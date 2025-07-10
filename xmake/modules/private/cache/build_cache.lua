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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        build_cache.lua
--

-- imports
import("core.base.bytes")
import("core.base.hashset")
import("core.base.global")
import("core.cache.memcache")
import("core.project.config")
import("core.project.policy")
import("core.project.project")
import("utils.ci.is_running", {alias = "ci_is_running"})
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
        if result == nil and target and target.policy then
            result = target:policy("build.ccache")
        end
        if result == nil and os.isfile(os.projectfile()) then
            local policy = project.policy("build.ccache")
            if policy ~= nil then
                result = policy
            end
        end
        -- disable ccache on ci
        if result == nil and ci_is_running() then
            local action_build_cache = _g._ACTION_BUILD_CACHE
            if action_build_cache == nil then
                action_build_cache = os.getenv("XMAKE_ACTION_BUILD_CACHE")
                _g._ACTION_BUILD_CACHE = action_build_cache or false
            end
            -- we cannot disable it if github-action-setup-xmake/build-cache is enabled
            if not action_build_cache then
                result = false
            end
        end
        -- disable ccache for msvc, because cl.exe preprocessor is too slower
        -- @see https://github.com/xmake-io/xmake/issues/3532
        if result == nil and is_host("windows") and
            target and target.has_tool and target:has_tool("cxx", "cl") then
            result = false
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
function cachekey(program, info, opt)
    local cppflags = info.cppflags
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

    if opt.preprocess then
        table.insert(items, hash.xxhash128(info.cppfile))
    end

    if opt.envs then
        local basename = path.basename(program)
        if basename == "cl" then
            for _, name in ipairs({"WindowsSDKVersion", "VCToolsVersion", "LIB"}) do
                local val = opt.envs[name]
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
    local cachedir = _g.cachedir
    if not cachedir then
        cachedir = config.get("ccachedir")
        if not cachedir and project.policy("build.ccache.global_storage") then
            cachedir = path.join(global.directory(), ".build_cache")
        end
        if not cachedir then
            cachedir = path.join(config.builddir(), ".build_cache")
        end
        _g.cachedir = path.absolute(cachedir)
    end
    return cachedir
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
    local cache_hit_count = (_g.cache_hit_count or 0)
    local total_count = (_g.total_count or 0)
    if total_count > 0 then
        return math.floor(cache_hit_count * 100 / total_count)
    end
    return 0
end

-- dump stats
function dump_stats()
    local total_count = (_g.total_count or 0)
    local cache_hit_count = (_g.cache_hit_count or 0)
    local cache_miss_count = total_count - cache_hit_count
    local newfiles_count = (_g.newfiles_count or 0)
    local remote_hit_count = (_g.remote_hit_count or 0)
    local remote_newfiles_count = (_g.remote_newfiles_count or 0)
    local preprocess_error_count = (_g.preprocess_error_count or 0)
    local compile_fallback_count = (_g.compile_fallback_count or 0)
    local compile_total_time = (_g.compile_total_time or 0)
    local cache_hit_total_time = (_g.cache_hit_total_time or 0)
    local cache_miss_total_time = (_g.cache_miss_total_time or 0)
    vprint("")
    vprint("build cache stats:")
    vprint("cache directory: %s", rootdir())
    vprint("cache hit rate: %d%%", hitrate())
    vprint("cache hit: %d", cache_hit_count)
    vprint("cache hit total time: %0.3fs", cache_hit_total_time / 1000.0)
    vprint("cache miss: %d", cache_miss_count)
    vprint("cache miss total time: %0.3fs", cache_miss_total_time / 1000.0)
    vprint("new cached files: %d", newfiles_count)
    vprint("remote cache hit: %d", remote_hit_count)
    vprint("remote new cached files: %d", remote_newfiles_count)
    vprint("preprocess failed: %d", preprocess_error_count)
    vprint("compile fallback count: %d", compile_fallback_count)
    vprint("compile total time: %0.3fs", compile_total_time / 1000.0)
    vprint("")
end

-- get object file
function get(cachekey)
    _g.total_count = (_g.total_count or 0) + 1
    local objectfile_cached = path.join(rootdir(), cachekey:sub(1, 2):lower(), cachekey)
    local objectfile_infofile = objectfile_cached .. ".txt"
    if os.isfile(objectfile_cached) then
        _g.cache_hit_count = (_g.cache_hit_count or 0) + 1
        return objectfile_cached, objectfile_infofile
    elseif remote_cache_client.is_connected() then
        return try
        {
            function ()
                if not remote_cache_client.singleton():unreachable() then
                    local exists, extrainfo = remote_cache_client.singleton():pull(cachekey, objectfile_cached)
                    if exists and os.isfile(objectfile_cached) then
                        _g.cache_hit_count = (_g.cache_hit_count or 0) + 1
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
    opt = opt or {}

    local info
    -- support preprocess?
    if is_supported(opt.tool:kind()) then
        -- do preprocess
        local preprocess = assert(opt.preprocess, "preprocessor not found!")
        local compile = assert(opt.compile, "compiler not found!")
        info = preprocess(program, argv, opt)
        if info then
            local cachekey = cachekey(program, info, {envs = opt.envs, preprocess = true})
            local cache_hit_start_time = os.mclock()
            local objectfile_cached, objectfile_infofile = get(cachekey)
            if objectfile_cached then
                os.cp(objectfile_cached, info.objectfile)
                -- we need to update mtime for incremental compilation
                -- @see https://github.com/xmake-io/xmake/issues/2620
                os.touch(info.objectfile, {mtime = os.time()})
                -- we need to get outdata/errdata to show warnings,
                -- @see https://github.com/xmake-io/xmake/issues/2452
                if objectfile_infofile and os.isfile(objectfile_infofile) then
                    local extrainfo = io.load(objectfile_infofile)
                    info.outdata = extrainfo.outdata
                    info.errdata = extrainfo.errdata
                end
                _g.cache_hit_total_time = (_g.cache_hit_total_time or 0) + (os.mclock() - cache_hit_start_time)
            else
                -- do compile
                local preprocess_outdata = info.outdata
                local preprocess_errdata = info.errdata
                local compile_start_time = os.mclock()
                local compile_fallback = opt.compile_fallback
                if compile_fallback then
                    local ok = try {function () compile(program, info, opt); return true end}
                    if not ok then
                        -- we fallback to compile original source file if compiling preprocessed file fails.
                        -- https://github.com/xmake-io/xmake/issues/2467
                        local outdata, errdata = compile_fallback()
                        info.outdata = outdata
                        info.errdata = errdata
                        _g.compile_fallback_count = (_g.compile_fallback_count or 0) + 1
                    end
                else
                    compile(program, info, opt)
                end
                -- if no compiler output, we need use preprocessor output, because it maybe contains warning output
                if not info.outdata or #info.outdata == 0 then
                    info.outdata = preprocess_outdata
                end
                if not info.errdata or #info.errdata == 0 then
                    info.errdata = preprocess_errdata
                end
                _g.compile_total_time = (_g.compile_total_time or 0) + (os.mclock() - compile_start_time)
                if cachekey then
                    local extrainfo
                    if info.outdata and #info.outdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.outdata = info.outdata
                    end
                    if info.errdata and #info.errdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.errdata = info.errdata
                    end
                    local cache_miss_start_time = os.mclock()
                    put(cachekey, info.objectfile, extrainfo)
                    _g.cache_miss_total_time = (_g.cache_miss_total_time or 0) + (os.mclock() - cache_miss_start_time)
                end
            end
            os.rm(info.cppfile)
        else
            _g.preprocess_error_count = (_g.preprocess_error_count or 0) + 1
        end
    else
        info = {
            -- Do not use depfile flag to generate cache key
            cppflags = opt.origin_flags,
            outputfile = opt.outputfile
        }
        local cachekey = cachekey(program, info, {envs = envs})
        local cache_hit_start_time = os.mclock()
        local objectfile_cached, objectfile_infofile = get(cachekey)
        if objectfile_cached then
            os.cp(objectfile_cached, info.outputfile)
            -- we need to update mtime for incremental compilation
            -- @see https://github.com/xmake-io/xmake/issues/2620
            os.touch(info.outputfile, {mtime = os.time()})
            -- we need to get outdata/errdata to show warnings,
            -- @see https://github.com/xmake-io/xmake/issues/2452
            if objectfile_infofile and os.isfile(objectfile_infofile) then
                local extrainfo = io.load(objectfile_infofile)
                info.outdata = extrainfo.outdata
                info.errdata = extrainfo.errdata
            end
            _g.cache_hit_total_time = (_g.cache_hit_total_time or 0) + (os.mclock() - cache_hit_start_time)
        else
            -- do compile
            local compile_start_time = os.mclock()
            local outdata, errdata = os.iorunv(program, argv, {envs = opt.envs})
            _g.compile_total_time = (_g.compile_total_time or 0) + (os.mclock() - compile_start_time)
            if cachekey then
                local extrainfo
                if info.outdata and #info.outdata ~= 0 then
                    extrainfo = extrainfo or {}
                    extrainfo.outdata = info.outdata
                end
                if info.errdata and #info.errdata ~= 0 then
                    extrainfo = extrainfo or {}
                    extrainfo.errdata = info.errdata
                end
                local cache_miss_start_time = os.mclock()
                put(cachekey, info.outputfile, extrainfo)
                _g.cache_miss_total_time = (_g.cache_miss_total_time or 0) + (os.mclock() - cache_miss_start_time)
            end
        end
    end

    return info
end
