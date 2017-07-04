--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_program.lua
--

-- define module
local sandbox_lib_detect_find_program = sandbox_lib_detect_find_program or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local option    = require("base/option")
local project   = require("project/project")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")
local cache     = require("sandbox/modules/import/lib/detect/cache")

-- globals
local checking  = nil

-- check program
function sandbox_lib_detect_find_program._check(program, check)

    -- no check script? attempt to run it directly
    if not check then
        return 0 == os.execv(program, {"--version"}, os.nuldev(), os.nuldev())
    end

    -- check it
    local ok = false
    local errors = nil
    if type(check) == "string" then
        ok, errors = os.runv(program, {check})
    else
        ok, errors = sandbox.load(check, program) 
    end

    -- check failed? print verbose error info
    if not ok then
        utils.verror(errors)
    end

    -- ok?
    return ok
end

-- find program
function sandbox_lib_detect_find_program._find(name, pathes, check)

    -- attempt to check it directly in current environment 
    if sandbox_lib_detect_find_program._check(name, check) then
        return name
    end

    -- attempt to check it from the given directories
    if not path.is_absolute(name) then
        for _, _path in ipairs(table.wrap(pathes)) do

            -- format path for builtin variables
            if type(_path) == "function" then
                local ok, results = sandbox.load(_path) 
                if ok then
                    _path = results or ""
                else 
                    raise(results)
                end
            else
                _path = vformat(_path)
            end

            -- get program path
            local program_path = nil
            if os.isfile(_path) then
                program_path = _path
            elseif os.isdir(_path) then
                program_path = path.join(_path, name)
            end

            -- the program path
            if program_path and os.isexec(program_path) then
                -- check it
                if sandbox_lib_detect_find_program._check(program_path, check) then
                    return program_path
                end
            end
        end
    end

    -- attempt to check it use `which program` command
    if os.host() ~= "windows" then
        local ok, program_path = os.iorunv("which", {name})
        if ok and program_path then
            -- check it
            program_path = program_path:trim()
            if os.isexec(program_path) then
                if sandbox_lib_detect_find_program._check(program_path, check) then
                    return program_path
                end
            end
        end
    end
end

-- find program
--
-- @param name      the program name
-- @param pathes    the program pathes (.e.g dirs, pathes, winreg pathes, script pathes)
-- @param check     the check script or command 
--
-- @return          the program name or path
--
-- @code
--
-- local program = find_program("ccache")
-- local program = find_program("ccache", {"/usr/bin", "/usr/local/bin"})
-- local program = find_program("ccache", {"/usr/bin", "/usr/local/bin"}, "--help") -- simple check command: ccache --help
-- local program = find_program("ccache", {"/usr/bin", "/usr/local/bin"}, function (program) os.run("%s -h", program) end)
-- local program = find_program("ccache", {"$(env PATH)", "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debugger)"})
-- local program = find_program("ccache", {"$(env PATH)", function () return "/usr/local/bin" end})
--
-- @endcode
--
function sandbox_lib_detect_find_program.main(name, pathes, check)

    -- @note avoid detect the same program in the same time leading to deadlock if running in the coroutine (.e.g ccache)
    local coroutine_running = coroutine.running()
    if coroutine_running then
        while checking ~= nil and checking == name do
            coroutine.yield()
        end
    end

    -- attempt to get result from cache first
    local cacheinfo = cache.load("find_program") 
    local result = cacheinfo[name]
    if result ~= nil then
        return utils.ifelse(result, result, nil)
    end

    -- add default search pathes 
    if os.host() ~= "windows" then
        pathes = table.join(table.wrap(pathes), "/usr/local/bin", "/usr/bin")
    end

    -- find executable program
    checking = utils.ifelse(coroutine_running, name, nil)
    result = sandbox_lib_detect_find_program._find(name, pathes, check) 
    checking = nil

    -- cache result
    cacheinfo[name] = utils.ifelse(result, result, false)

    -- save cache info
    cache.save("find_program", cacheinfo)

    -- trace
    if option.get("verbose") then
        if result then
            utils.cprint("checking for the %s ... ${green}%s", name, result)
        else
            utils.cprint("checking for the %s ... ${red}no", name)
        end
    end

    -- ok?
    return result
end

-- return module
return sandbox_lib_detect_find_program
