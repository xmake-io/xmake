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
-- @file        has_flags.lua
--

-- imports
import("core.base.option")
import("core.base.scheduler")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_tool")

-- has the given flags for the current tool?
--
-- @param name      the tool name
-- @param flags     the flags
-- @param opt       the argument options, e.g. {force = true, verbose = false, program = "", sysflags = {}, flagkind = "cxflag", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]", flagskey = "custom key" }
--
-- @return          true or false
--
-- @code
-- local ok = has_flags("clang", "-g")
-- local ok = has_flags("clang", {"-g", "-O0"}, {program = "xcrun -sdk macosx clang"})
-- local ok = has_flags("clang", "-g", {toolkind = "cxx"})
-- local ok = has_flags("clang", "-g", {on_check = function (ok, errors) return ok, errors end})
-- @endcode
--
function main(name, flags, opt)

    -- wrap flags first
    flags = table.wrap(flags)

    -- init options
    opt = opt or {}
    opt.flagskey = opt.flagskey or table.concat(flags, " ")
    opt.sysflags = table.wrap(opt.sysflags)

    -- find tool program and version first
    opt.version = true
    local tool = find_tool(name, opt)
    if not tool then
        return false
    end

    -- init tool
    opt.toolname   = tool.name
    opt.program    = tool.program
    opt.programver = tool.version

    -- get tool platform
    local plat = opt.plat or config.get("plat") or os.host()

    -- get tool architecture
    --
    -- some tools select arch by path environment, not be flags, e.g. cl.exe of msvc)
    -- so, it will affect the cache result
    --
    local arch = opt.arch or config.get("arch") or os.arch()

    -- init cache key
    local key = plat .. "_" .. arch .. "_" .. tool.program .. "_"
              .. (tool.version or "") .. "_" .. (opt.toolkind or "")
              .. "_" .. (opt.flagkind or "") .. "_" .. table.concat(opt.sysflags, " ") .. "_" .. opt.flagskey

    -- @note avoid detect the same program in the same time if running in the coroutine (e.g. ccache)
    local coroutine_running = scheduler.co_running()
    if coroutine_running then
        while _g._checking ~= nil and _g._checking == key do
            scheduler.co_yield()
        end
    end

    -- attempt to get result from cache first
    local cacheinfo = detectcache:get("lib.detect.has_flags") or {}
    local result = cacheinfo[key]
    if result ~= nil and not opt.force then
        return result
    end

    -- generate all checked flags
    local checkflags = table.join(flags, opt.sysflags)

    -- split flag group, e.g. "-I /xxx" => {"-I", "/xxx"}
    local results = {}
    for _, flag in ipairs(checkflags) do
        flag = flag:trim()
        if #flag > 0 then
            if flag:find(" ", 1, true) then
                table.join2(results, os.argv(flag))
            else
                table.insert(results, flag)
            end
        end
    end
    checkflags = results

    -- detect.tools.xxx.has_flags(flags, opt)?
    _g._checking = coroutine_running and key or nil
    local hasflags = import("detect.tools." .. tool.name .. ".has_flags", {try = true})
    local errors = nil
    if hasflags then
        result, errors = hasflags(checkflags, opt)
    else
        result = try { function () os.runv(tool.program, checkflags, {envs = opt.envs}); return true end, catch { function (errs) errors = errs end }}
    end
    if opt.on_check then
        result, errors = opt.on_check(result, errors)
    end
    _g._checking = nil
    result = result or false

    -- trace
    if option.get("verbose") or option.get("diagnosis") or opt.verbose then
        cprintf("${dim}checking for flags (")
        io.write(opt.flagskey)
        cprint("${dim}) ... %s", result and "${color.success}${text.success}" or "${color.nothing}${text.nothing}")
        if option.get("diagnosis") then
            cprint("${dim}> %s \"%s\"", path.filename(tool.program), table.concat(checkflags, "\" \""))
            if errors and #tostring(errors) > 0 then
                cprint("${color.warning}checkinfo:${clear dim} %s", tostring(errors):trim())
            end
        end
    end

    -- save result to cache
    cacheinfo[key] = result
    detectcache:set("lib.detect.has_flags", cacheinfo)
    detectcache:save()
    return result
end

