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
-- @file        features.lua
--

-- imports
import("lib.detect.find_tool")
import("core.base.scheduler")

-- get all features of the current tool
--
-- @param name      the tool name
-- @param opt       the argument options, e.g. {program = "", flags = {}}
--
-- @return          the features dictionary
--
-- @code
-- local features = features("clang")
-- local features = features("clang", {flags = "-O0", program = "xcrun -sdk macosx clang"})
-- local features = features("clang", {flags = {"-g", "-O0"}, envs = {PATH = ""}})
-- @endcode
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find tool program and version first
    opt.version = true
    local tool = find_tool(name, opt)
    if not tool then
        return {}
    end

    -- init tool
    opt.toolname   = tool.name
    opt.program    = tool.program
    opt.programver = tool.version

    -- init cache and key
    local key     = tool.program .. "_" .. (tool.version or "") .. "_" .. table.concat(table.wrap(opt.flags), ",")
    _g._RESULTS = _g._RESULTS or {}
    local results = _g._RESULTS

    -- @note avoid detect the same program in the same time if running in the coroutine (e.g. ccache)
    local coroutine_running = scheduler.co_running()
    if coroutine_running then
        while _g._checking ~= nil and _g._checking == key do
            scheduler.co_yield()
        end
    end

    -- get result from the cache first
    local result = results[key]
    if result ~= nil then
        return result
    end

    -- detect.tools.xxx.features(opt)?
    _g._checking = coroutine_running and key or nil
    local features = import("detect.tools." .. tool.name .. ".features", {try = true})
    if features then
        result = features(opt)
    end
    _g._checking = nil

    result = result or {}
    results[key] = result
    return result
end
