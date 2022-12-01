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
-- @file        find_programver.lua
--

-- define module
local sandbox_lib_detect_find_programver = sandbox_lib_detect_find_programver or {}

-- load modules
local os          = require("base/os")
local path        = require("base/path")
local table       = require("base/table")
local utils       = require("base/utils")
local option      = require("base/option")
local semver      = require("base/semver")
local project     = require("project/project")
local detectcache = require("cache/detectcache")
local sandbox     = require("sandbox/sandbox")
local raise       = require("sandbox/modules/raise")
local scheduler   = require("sandbox/modules/import/core/base/scheduler")

-- globals
local checking  = nil

-- find program version
--
-- @param program   the program
-- @param opt       the options, e.g. {command = "--version", parse = "(%d+%.?%d*%.?%d*.-)%s", verbose = true, force = true, cachekey = "xxx"}
--                    - opt.command   the version command string or script, default: --version
--                    - opt.parse     the version parse script or lua match pattern
--
-- @return          the version string
--
-- @code
-- local version = find_programver("ccache")
-- local version = find_programver("ccache", {command = "-v"})
-- local version = find_programver("ccache", {command = "--version", parse = "(%d+%.?%d*%.?%d*.-)%s"})
-- local version = find_programver("ccache", {command = "--version", parse = function (output) return output:match("(%d+%.?%d*%.?%d*.-)%s") end})
-- local version = find_programver("ccache", {command = function () return os.iorun("ccache --version") end})
-- @endcode
--
function sandbox_lib_detect_find_programver.main(program, opt)

    -- init options
    opt = opt or {}

    -- @note avoid detect the same program in the same time leading to deadlock if running in the coroutine (e.g. ccache)
    local coroutine_running = scheduler.co_running()
    if coroutine_running then
        while checking ~= nil and checking == program do
            scheduler.co_yield()
        end
    end

    -- init cachekey
    local cachekey = "find_programver"
    if opt.cachekey then
        cachekey = cachekey .. "_" .. opt.cachekey
    end

    -- attempt to get result from cache first
    local result = detectcache:get2(cachekey, program)
    if result ~= nil and not opt.force then
        return result and result or nil
    end

    -- attempt to get version output info
    checking = coroutine_running and program or nil
    local ok = false
    local outdata = nil
    local command = opt.command
    if type(command) == "function" then
        ok, outdata = sandbox.load(command)
        if not ok and outdata and option.get("diagnosis") then
            utils.cprint("${color.warning}checkinfo: ${clear dim}" .. outdata)
        end
    else
        ok, outdata = os.iorunv(program, {command or "--version"}, {envs = opt.envs})
    end
    checking = nil

    -- find version info
    if ok and outdata and #outdata > 0 then
        local parse = opt.parse
        if type(parse) == "function" then
            ok, result = sandbox.load(parse, outdata)
            if not ok and result and option.get("diagnosis") then
                utils.cprint("${color.warning}checkinfo: ${clear dim}" .. result)
                result = nil
            end
        elseif parse == nil or type(parse) == "string" then
            result = semver.match(outdata, 1, parse)
            if result then
                result = result:rawstr()
            end
        end
    end

    -- save result
    detectcache:set2(cachekey, program, result and result or false)
    detectcache:save()
    return result
end

-- return module
return sandbox_lib_detect_find_programver
