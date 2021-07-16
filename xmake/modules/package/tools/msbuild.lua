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
-- @file        msbuild.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- get msvc
function _get_msvc(package)
    local msvc = toolchain.load("msvc", {plat = package:plat(), arch = package:arch()})
    assert(msvc:check(), "vs not found!") -- we need check vs envs if it has been not checked yet
    return msvc
end

-- get the build environments
function buildenvs(package, opt)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- build package
function build(package, configs, opt)

    -- init options
    opt = opt or {}

    -- pass configurations
    local argv = {}
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
    local envs = opt.envs or buildenvs(package, opt)
    local msbuild = find_tool("msbuild", {envs = envs})
    os.vrunv(msbuild.program, argv, {envs = envs})
end
