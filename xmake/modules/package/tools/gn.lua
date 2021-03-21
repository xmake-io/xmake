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
-- @file        gn.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_tool")
import("package.tools.ninja")

-- get build directory
function _get_buildir(opt)
    if opt and opt.buildir then
        return opt.buildir
    else
        _g.buildir = _g.buildir or ("build_" .. hash.uuid4():split('%-')[1])
        return _g.buildir
    end
end

-- get configs
function _get_configs(package, configs, opt)
    return configs
end

-- get the build environments
function buildenvs(package, opt)
    local envs = {}
    if package:is_plat("windows") then
        table.join2(envs, toolchain.load("msvc"):runenvs())
    end
    return envs
end

-- generate build files for ninja
function generate(package, configs, opt)

    -- init options
    opt = opt or {}

    -- pass configurations
    local argv = {}
    local args = {}
    table.insert(argv, "gen")
    table.insert(argv, _get_buildir(opt))
    for name, value in pairs(_get_configs(package, configs, opt)) do
        if type(value) == "string" then
            table.insert(args, name .. "=\"" .. value .. "\"")
        elseif type(value) == "table" then
            table.insert(args, name .. "=[\"" .. table.concat(value, "\",\"") .. "\"]")
        else
            table.insert(args, name .. "=" .. tostring(value))
        end
    end
    table.insert(argv, "--args=" .. table.concat(args, ' '))

    -- do configure
    local gn = assert(find_tool("gn"), "gn not found!")
    os.vrunv(gn.program, argv, {envs = opt.envs or buildenvs(package)})
end

-- build package
function build(package, configs, opt)

    -- generate build files
    opt = opt or {}
    generate(package, configs, opt)

    -- do build
    local buildir = _get_buildir(opt)
    ninja.build(package, {}, {buildir = buildir, envs = opt.envs or buildenvs(package, opt)})
end

-- install package
function install(package, configs, opt)

    -- generate build files
    opt = opt or {}
    generate(package, configs, opt)

    -- do build and install
    local buildir = _get_buildir(opt)
    ninja.install(package, {}, {buildir = buildir, envs = opt.envs or buildenvs(package, opt)})
end
