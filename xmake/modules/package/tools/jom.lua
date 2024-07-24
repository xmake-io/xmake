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
-- @file        jom.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- get the number of parallel jobs
function _get_parallel_njobs(opt)
    return opt.jobs or option.get("jobs") or tostring(os.default_njob())
end

-- get msvc
function _get_msvc(package)
    local msvc = package:toolchain("msvc")
    assert(msvc:check(), "vs not found!") -- we need to check vs envs if it has been not checked yet
    return msvc
end

-- get the build environments
function buildenvs(package, opt)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- do make
function make(package, argv, opt)
    opt = opt or {}
    local program
    local runenvs = opt.envs or buildenvs(package)
    local tool = find_tool("jom", {envs = runenvs})
    if tool then
        program = tool.program
    end
    assert(program, "jom not found!")
    os.vrunv(program, argv or {}, {envs = runenvs, curdir = opt.curdir})
end

-- build package
function build(package, configs, opt)
    opt = opt or {}
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "VERBOSE=1")
    end
    local jobs = _get_parallel_njobs(opt)
    local jom_argv = {"/K"}
    if jobs then
        table.insert(jom_argv, "/J")
        table.insert(jom_argv, tostring(jobs))
    end
    configs = table.join(jom_argv, configs)
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
    make(package, argv, opt)
end

-- install package
function install(package, configs, opt)

    -- do build
    opt = opt or {}
    build(package, configs, opt)

    -- do install
    local argv = {"install"}
    if option.get("verbose") then
        table.insert(argv, "VERBOSE=1")
        table.insert(argv, "V=1")
    end
    make(package, argv, opt)
end
