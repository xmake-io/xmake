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
-- @file        nmake.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- build package
function build(package, configs, opt)

    -- init options
    opt = opt or {}

    -- pass configurations
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "VERBOSE=1")
    end
    for name, value in pairs(configs) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(argv, value)
            else
                table.insert(argv, name .. "=" .. value)
            end
        end
    end

    -- do build
    local runenvs = toolchain.load("msvc"):runenvs()
    local nmake = find_tool("nmake", {envs = runenvs})
    os.vrunv(nmake.program, argv, {envs = runenvs})
end

-- install package
function install(package, configs)

    -- pass configurations
    local argv = {"install"}
    if option.get("verbose") then
        table.insert(argv, "VERBOSE=1")
    end
    for name, value in pairs(configs) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(argv, value)
            else
                table.insert(argv, name .. "=" .. value)
            end
        end
    end

    -- do install
    local runenvs = toolchain.load("msvc"):runenvs()
    local nmake = find_tool("nmake", {envs = runenvs})
    os.vrunv(nmake.program, argv, {envs = runenvs})
end
