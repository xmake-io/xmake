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
-- @file        find_tool.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find tool from modules
function _find_from_modules(name, opt)

    -- strip arguments with spaces
    name = name:split("%s+")[1]

    -- replace "+" to "x"
    name = name:gsub("%+", "x")

    -- strip suffix on windows
    if os.host() == "windows" and name:endswith(".exe") then
        name = name:sub(1, #name - 4)
    end

    -- "detect.tool.find_xxx" exists?
    if os.isfile(path.join(os.programdir(), "modules", "detect", "tool", "find_" .. name .. ".lua")) then
        local find_tool = import("detect.tool.find_" .. name)
        if find_tool then
            return find_tool(opt)
        end
    end
end

-- find tool
--
-- @param name      the tool name
-- @param opt       the options, .e.g {program = "xcrun -sdk macosx clang", pathes = {"/usr/bin"}, check = function (tool) os.run("%s -h", tool) end, version = true}
--
-- @return          the tool name or path, version
--
-- @code
--
-- local tool = find_tool("clang")
-- local tool = find_tool("clang", {program = "xcrun -sdk macosx clang"})
-- local tool = find_tool("clang", {pathes = {"/usr/bin", "/usr/local/bin"}})
-- local tool = find_tool("clang", {check= "--help"}) -- simple check command: ccache --help
-- local tool = find_tool("clang", {check = function (tool) os.run("%s -h", tool) end})
-- local tool = find_tool("clang", {pathes = {"$(env PATH)", "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debugger)"}})
-- local tool = find_tool("clang", {pathes = {"$(env PATH)", function () return "/usr/bin"end}})
-- local tool, version = find_tool("ccache", {version = true})
--
-- @endcode
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- attempt to find tool from modules first
    local tool, version = _find_from_modules(name, opt)
    if tool then
        return tool, version
    end
 
    -- find tool
    tool = find_program(opt.program or name, opt.pathes, opt.check)

    -- find tool version
    local version = nil
    if tool and opt.version then
        version = find_programver(tool)
    end

    -- ok?
    return tool, version
end
