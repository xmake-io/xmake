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
-- @file        find_program.lua
--

-- define module
local sandbox_lib_detect_find_program = sandbox_lib_detect_find_program or {}

-- load modules
local os          = require("base/os")
local path        = require("base/path")
local option      = require("base/winos")
local table       = require("base/table")
local utils       = require("base/utils")
local option      = require("base/option")
local project     = require("project/project")
local detectcache = require("cache/detectcache")
local sandbox     = require("sandbox/sandbox")
local package     = require("package/package")
local raise       = require("sandbox/modules/raise")
local vformat     = require("sandbox/modules/vformat")
local scheduler   = require("sandbox/modules/import/core/base/scheduler")

-- globals
local checking  = nil

-- do check
function sandbox_lib_detect_find_program._do_check(program, opt)

    -- do not attempt to run program? check it fastly
    if opt.norun then
        return os.isfile(program)
    end

    -- no check script? attempt to run it directly
    if not opt.check then
        local ok, errors = os.runv(program, {"--version"}, {envs = opt.envs})
        if not ok and option.get("verbose") and option.get("diagnosis") then
            utils.cprint("${color.warning}checkinfo: ${clear dim}" .. errors)
        end
        return ok
    end

    -- check it
    local ok = false
    local errors = nil
    if type(opt.check) == "string" then
        ok, errors = os.runv(program, {opt.check}, {envs = opt.envs})
    else
        ok, errors = sandbox.load(opt.check, program)
    end

    -- check failed? print verbose error info
    if not ok and option.get("verbose") and option.get("diagnosis") then
        utils.cprint("${color.warning}checkinfo: ${clear dim}" .. errors)
    end
    return ok
end

-- check program
function sandbox_lib_detect_find_program._check(program, opt)
    local findname = program
    if os.subhost() == "windows" then
        if not program:endswith(".exe") and not program:endswith(".cmd") and not program:endswith(".bat") then
            findname = program .. ".exe"
        end
    elseif os.subhost() == "msys" and os.isfile(program) and os.filesize(program) < 256 then
        -- only a sh script on msys2? e.g. c:/msys64/usr/bin/7z
        -- we need use sh to wrap it, otherwise os.exec cannot run it
        program = "sh " .. program
        findname = program
    end
    if sandbox_lib_detect_find_program._do_check(findname, opt) then
        return program
    -- check "zig c++" without ".exe"
    -- https://github.com/xmake-io/xmake/issues/2232
    elseif findname ~= program and path.filename(program):find(" ", 1, true) and
        sandbox_lib_detect_find_program._do_check(program, opt) then
        return program
    end
end

-- find program from the given paths
function sandbox_lib_detect_find_program._find_from_paths(name, paths, opt)

    -- attempt to check it from the given directories
    if not path.is_absolute(name) then
        for _, _path in ipairs(table.wrap(paths)) do

            -- format path for builtin variables
            if type(_path) == "function" then
                local ok, results = sandbox.load(_path)
                if ok then
                    _path = results or ""
                else
                    raise(results)
                end
            elseif type(_path) == "string" then
                if _path:match("^%$%(env .+%)$") then
                    _path = path.splitenv(vformat(_path))
                else
                    _path = vformat(_path)
                end
            end

            for _, _s_path in ipairs(table.wrap(_path)) do

                -- get program path
                local program_path = nil
                if os.isfile(_s_path) then
                    program_path = _s_path
                elseif os.isdir(_s_path) then
                    program_path = path.join(_s_path, name)
                end

                -- the program path
                if program_path and (os.isexec(program_path) or os.isexec(program_path:split("%s")[1])) then
                    local program_path_real = sandbox_lib_detect_find_program._check(program_path, opt)
                    if program_path_real then
                        return program_path_real
                    end
                end
            end
        end
    end
end

-- find program from the xmake packages
function sandbox_lib_detect_find_program._find_from_packages(name, opt)

    -- get the manifest file of package, e.g. ~/.xmake/packages/g/git/1.1.12/ed41d5327fad3fc06fe376b4a94f62ef/manifest.txt
    opt = opt or {}
    local installdir = opt.installdir or path.join(package.installdir(), name:sub(1, 1), name, opt.require_version, opt.buildhash)
    local manifest_file = path.join(installdir, "manifest.txt")
    if not os.isfile(manifest_file) then
        return
    end

    -- get install directory of this package
    local installdir = path.directory(manifest_file)

    -- init paths
    local paths = {}
    local manifest = io.load(manifest_file)
    if manifest and manifest.envs then
        local pathenvs = manifest.envs.PATH
        if pathenvs then
            for _, pathenv in ipairs(pathenvs) do
                table.insert(paths, path.join(installdir, pathenv))
            end
        end
    end

    -- find it
    return sandbox_lib_detect_find_program._find_from_paths(name, paths, opt)
end

-- find program
function sandbox_lib_detect_find_program._find(name, paths, opt)

    -- attempt to find it from the given directories
    local program_path = sandbox_lib_detect_find_program._find_from_paths(name, paths, opt)
    if program_path then
        return program_path
    end

    -- attempt to find it from the xmake packages
    if opt.require_version and opt.buildhash then
        return sandbox_lib_detect_find_program._find_from_packages(name, opt)
    end

    -- attempt to find it from regists
    if os.host() == "windows" then
        local program_name = name:lower()
        if not program_name:endswith(".exe") then
            program_name = program_name .. ".exe"
        end
        program_path = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\" .. program_name)
        if program_path then
            program_path = program_path:trim()
            if os.isexec(program_path) then
                local program_path_real = sandbox_lib_detect_find_program._check(program_path, opt)
                if program_path_real then
                    return program_path_real
                end
            end
        end
    else
        -- attempt to find it use `which program` command
        local ok, program_path = os.iorunv("which", {name})
        if ok and program_path then
            program_path = program_path:trim()
            local program_path_real = sandbox_lib_detect_find_program._check(program_path, opt)
            if program_path_real then
                return program_path_real
            end
        end
    end

    -- attempt to find it from the some default $PATH and system directories
    local syspaths = {}
    --[[
    local envpaths = os.getenv("PATH")
    if envpaths then
        table.join2(syspaths, path.splitenv(envpaths))
    end]]
    if os.host() ~= "windows" then
        table.insert(syspaths, "/usr/local/bin")
        table.insert(syspaths, "/usr/bin")
    end
    if #syspaths > 0 then
        program_path = sandbox_lib_detect_find_program._find_from_paths(name, syspaths, opt)
        if program_path then
            return program_path
        end
    end

    -- attempt to find it directly in current environment
    --
    -- @note must be detected at the end, because full path is more accurate
    --
    local program_path_real = sandbox_lib_detect_find_program._check(name, opt)
    if program_path_real then
        return program_path_real
    end
end

-- find program
--
-- @param name      the program name
-- @param opt       the options, e.g. {paths = {"/usr/bin"}, check = function (program) os.run("%s -h", program) end, verbose = true, force = true, cachekey = "xxx"}
--                    - opt.paths     the program paths (e.g. dirs, paths, winreg paths, script paths)
--                    - opt.check     the check script or command
--                    - opt.norun     do not attempt to run program to check program fastly
--
-- @return          the program name or path
--
-- @code
--
-- local program = find_program("ccache")
-- local program = find_program("ccache", {paths = {"/usr/bin", "/usr/local/bin"}})
-- local program = find_program("ccache", {paths = {"/usr/bin", "/usr/local/bin"}, check = "--help"}) -- simple check command: ccache --help
-- local program = find_program("ccache", {paths = {"/usr/bin", "/usr/local/bin"}, check = function (program) os.run("%s -h", program) end})
-- local program = find_program("ccache", {paths = {"$(env PATH)", "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debugger)"}})
-- local program = find_program("ccache", {paths = {"$(env PATH)", function () return "/usr/local/bin" end}})
-- local program = find_program("ccache", {envs = {PATH = "xxx"}})
--
-- @endcode
--
function sandbox_lib_detect_find_program.main(name, opt)

    -- @note avoid detect the same program in the same time leading to deadlock if running in the coroutine (e.g. ccache)
    local coroutine_running = scheduler.co_running()
    if coroutine_running then
        while checking ~= nil and checking == name do
            scheduler.co_yield()
        end
    end

    -- init options
    opt = opt or {}

    -- init cachekey
    local cachekey = "find_program"
    if opt.cachekey then
        cachekey = cachekey .. "_" .. opt.cachekey
    end

    -- attempt to get result from cache first
    local result = detectcache:get2(cachekey, name)
    if result ~= nil and not opt.force then
        return result and result or nil
    end

    -- get paths from the opt.envs.PATH
    -- @note the wrong `pathes` word will be discarded, but the interface parameters will still be compatible
    local envs = opt.envs
    local paths = opt.paths or opt.pathes
    if envs and (envs.PATH or envs.path) then
        local pathenv = envs.PATH or envs.path
        if type(pathenv) == "string" then
            pathenv = path.splitenv(pathenv)
        end
        paths = table.join(table.wrap(opt.paths or opt.pathes), pathenv)
    end

    -- find executable program
    checking = coroutine_running and name or nil
    result = sandbox_lib_detect_find_program._find(name, paths, opt)
    checking = nil

    -- cache result
    detectcache:set2(cachekey, name, result and result or false)
    detectcache:save()

    -- trace
    if option.get("verbose") or opt.verbose then
        if result then
            utils.cprint("checking for %s ... ${color.success}%s", name, (name == result and "${text.success}" or result))
        else
            utils.cprint("checking for %s ... ${color.nothing}${text.nothing}", name)
        end
    end
    return result
end

-- return module
return sandbox_lib_detect_find_program
