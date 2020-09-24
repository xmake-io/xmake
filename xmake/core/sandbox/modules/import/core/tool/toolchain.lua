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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        toolchain.lua
--

-- define module
local sandbox_core_tool_toolchain = sandbox_core_tool_toolchain or {}

-- load modules
local platform  = require("platform/platform")
local toolchain = require("tool/toolchain")
local project   = require("project/project")
local raise     = require("sandbox/modules/raise")

-- get all toolchains list
function sandbox_core_tool_toolchain.list()
    local names = table.copy(platform.toolchains())
    if os.isfile(os.projectfile()) then
        for name, _ in pairs(project.toolchains()) do
            table.insert(names, name)
        end
    end
    return names
end

-- load the toolchain from the given name
function sandbox_core_tool_toolchain.load(name, opt)
    local instance, errors = toolchain.load(name, opt)
    if not instance then
        raise(errors)
    end
    return instance
end

-- return module
return sandbox_core_tool_toolchain
