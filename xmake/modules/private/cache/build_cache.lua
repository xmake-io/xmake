--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        build_cache.lua
--

-- imports
import("core.base.bytes")
import("core.base.hashset")
import("core.cache.memcache")
import("core.project.config")
import("core.project.policy")
import("core.project.project")
import("private.service.client_config")
import("private.service.remote_cache.client", {alias = "remote_cache_client"})

-- get memcache
function _memcache()
    local cache = _g.memcache
    if not cache then
        cache = memcache.cache("build_cache")
        _g.memcache = cache
    end
    return cache
end

-- get exist info
function _get_existinfo()
    local existinfo = _g.existinfo
    if existinfo == nil then
        existinfo = remote_cache_client.singleton():existinfo()
        _g.existinfo = existinfo
    end
    return existinfo
end

-- is enabled?
function is_enabled(target)
    local key = tostring(target or "all")
    local result = _memcache():get2("enabled", key)
    if result == nil then
        -- target may be option instance
        if target and target.policy then
            result = target:policy("build.ccache")
        end
        if result == nil and os.isfile(os.projectfile()) then
            local policy = project.policy("build.ccache")
            if policy ~= nil then
                result = policy
            end
        end
        if result == nil then
            result = config.get("ccache")
        end
        result = result or false
        _memcache():set2("enabled", key)
    end
    return result
end

-- is supported?
function is_supported(sourcekind)
    local sourcekinds = _g.sourcekinds
    if sourcekinds == nil then
        sourcekinds = hashset.of("cc", "cxx", "mm", "mxx")
        _g.sourcekinds = sourcekinds
    end
    return sourcekinds:has(sourcekind)
end

-- get cache key
function cachekey(program, cppinfo, envs)
    local cppfile = cppinfo.cppfile
    local cppflags = cppinfo.cppflags
    local items = {program}
    for _, cppflag in ipairs(cppflags) do
        if cppflag:startswith("-D") or cppflag:startswith("/D") then
            -- ignore `-Dxx` to improve the cache hit rate, as some source files may not use the defined macros.
            -- @see https://github.com/xmake-io/xmake/issues/2425
        else
            table.insert(items, cppflag)
        end
    end
    table.sort(items)
    table.insert(items, hash.xxhash128(cppfile))
    if envs then
        local basename = path.basename(program)
        if basename == "cl" then
            for _, name in ipairs({"WindowsSDKVersion", "VCToolsVersion", "LIB"}) do
                local val = envs[name]
                if val then
                    table.insert(items, val)
                end
            end
        end
    end
    return hash.xxhash128(bytes(table.concat(items, "")))
end

-- get cache root directory
function rootdir()
    local cachedir = config.get("ccachedir")
    return cachedir or path.join(config.buildir(), ".build_cache")
end

-- clean cached files
function clean()
    os.rm(rootdir())
    if remote_cache_client.is_connected() then
        client_config.load()
        remote_cache_client.singleton():clean()
    end
end

-- get hit rate
function hitrate()
    local hit_count = (_g.hit_count or 0)
    local total_count = (_g.total_count or 0)
    if total_count > 0 then
        return math.floor(hit_count * 100 / total_count)
    end
    return 0
end

-- dump stats
function dump_stats()
    local hit_count = (_g.hit_count or 0)
    local total_count = (_g.total_count or 0)
    local newfiles_count = (_g.newfiles_count or 0)
    local remote_hit_count = (_g.remote_hit_count or 0)
    local remote_newfiles_count = (_g.remote_newfiles_count or 0)
    local preprocess_error_count = (_g.preprocess_error_count or 0)
    local compile_fallback_count = (_g.compile_fallback_count or 0)
    vprint("")
    vprint("build cache stats:")
    vprint("cache directory: %s", rootdir())
    vprint("cache hit rate: %d%%", hitrate())
    vprint("cache hit: %d", hit_count)
    vprint("cache miss: %d", total_count - hit_count)
    vprint("new cached files: %d", newfiles_count)
    vprint("remote cache hit: %d", remote_hit_count)
    vprint("remote new cached files: %d", remote_newfiles_count)
    vprint("preprocess failed: %d", preprocess_error_count)
    vprint("compile fallback count: %d", compile_fallback_count)
    vprint("")
end

-- get object file
function get(cachekey)
    _g.total_count = (_g.total_count or 0) + 1
    local objectfile_cached = path.join(rootdir(), cachekey:sub(1, 2):lower(), cachekey)
    local objectfile_infofile = objectfile_cached .. ".txt"
    if os.isfile(objectfile_cached) then
        _g.hit_count = (_g.hit_count or 0) + 1
        return objectfile_cached, objectfile_infofile
    elseif remote_cache_client.is_connected() then
        try
        {
            function ()
                if not remote_cache_client.singleton():unreachable() then
                    local exists, extrainfo = remote_cache_client.singleton():pull(cachekey, objectfile_cached)
                    if exists and os.isfile(objectfile_cached) then
                        _g.hit_count = (_g.hit_count or 0) + 1
                        _g.remote_hit_count = (_g.remote_hit_count or 0) + 1
                        if extrainfo then
                            io.save(objectfile_infofile, extrainfo)
                        end
                        return objectfile_cached, objectfile_infofile
                    end
                end
            end,
            catch
            {
                function (errors)
                    if errors and policy.build_warnings() then
                        cprint("${color.warning}fallback to the local cache, %s", tostring(errors))
                    end
                end
            }
        }
    end
end

-- put object file
function put(cachekey, objectfile, extrainfo)
    local objectfile_cached = path.join(rootdir(), cachekey:sub(1, 2):lower(), cachekey)
    local objectfile_infofile = objectfile_cached .. ".txt"
    os.cp(objectfile, objectfile_cached)
    if extrainfo then
        io.save(objectfile_infofile, extrainfo)
    end
    _g.newfiles_count = (_g.newfiles_count or 0) + 1
    if remote_cache_client.is_connected() then
        try
        {
            function ()
                if not remote_cache_client.singleton():unreachable() then
                    -- this file does not exist in remote server? push it to server
                    --
                    -- we use the bloom filter to approximate whether it exists or not,
                    -- which may result in a few less files being uploaded, but that's fine.
                    local existinfo = _get_existinfo()
                    if not existinfo or not existinfo:get(cachekey) then
                        -- existinfo is just an initial snapshot, we need to go further and determine if the current file exists
                        local cacheinfo = remote_cache_client.singleton():cacheinfo(cachekey)
                        if not cacheinfo or not cacheinfo.exists then
                            _g.remote_newfiles_count = (_g.remote_newfiles_count or 0) + 1
                            remote_cache_client.singleton():push(cachekey, objectfile, extrainfo)
                        end
                    end
                end
            end,
            catch
            {
                function (errors)
                    if errors and policy.build_warnings() then
                        cprint("${color.warning}fallback to the local cache, %s", tostring(errors))
                    end
                end
            }
        }
    end
end

-- build with cache
function build(program, argv, opt)

    -- do preprocess
    opt = opt or {}
    local preprocess = assert(opt.preprocess, "preprocessor not found!")
    local compile = assert(opt.compile, "compiler not found!")
    local cppinfo = preprocess(program, argv, opt)
    if cppinfo then
        local cachekey = cachekey(program, cppinfo, opt.envs)
        local objectfile_cached, objectfile_infofile = get(cachekey)
        if objectfile_cached then
            os.cp(objectfile_cached, cppinfo.objectfile)
            -- we need update mtime for incremental compilation
            -- @see https://github.com/xmake-io/xmake/issues/2620
            os.touch(cppinfo.objectfile, {mtime = os.time()})
            -- we need get outdata/errdata to show warnings,
            -- @see https://github.com/xmake-io/xmake/issues/2452
            if objectfile_infofile and os.isfile(objectfile_infofile) then
                local extrainfo = io.load(objectfile_infofile)
                cppinfo.outdata = extrainfo.outdata
                cppinfo.errdata = extrainfo.errdata
            end
        else
            -- do compile
            local compile_fallback = opt.compile_fallback
            if compile_fallback then
                local ok = try {function () compile(program, cppinfo, opt); return true end}
                if not ok then
                    -- we fallback to compile original source file if compiling preprocessed file fails.
                    -- https://github.com/xmake-io/xmake/issues/2467
                    local outdata, errdata = compile_fallback()
                    cppinfo.outdata = outdata
                    cppinfo.errdata = errdata
                    _g.compile_fallback_count = (_g.compile_fallback_count or 0) + 1
                end
            else
                compile(program, cppinfo, opt)
            end
            if cachekey then
                local extrainfo
                if cppinfo.outdata and #cppinfo.outdata ~= 0 then
                    extrainfo = extrainfo or {}
                    extrainfo.outdata = cppinfo.outdata
                end
                if cppinfo.errdata and #cppinfo.errdata ~= 0 then
                    extrainfo = extrainfo or {}
                    extrainfo.errdata = cppinfo.errdata
                end
                put(cachekey, cppinfo.objectfile, extrainfo)
            end
        end
        os.rm(cppinfo.cppfile)
    else
        _g.preprocess_error_count = (_g.preprocess_error_count or 0) + 1
    end
    return cppinfo
end
