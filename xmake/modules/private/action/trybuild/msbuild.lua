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
import("core.project.config")
import("core.project.project")
import("core.tool.toolchain")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- find project file
function _find_projectfile()
    return find_file("*.sln", os.curdir())
end

-- detect build-system and configuration file
function detect()
    if is_subhost("windows") then
        return _find_projectfile()
    end
end

-- do clean
function clean()
    local projectfile = _find_projectfile()
    local runenvs = toolchain.load("msvc"):runenvs()
    local msbuild = find_tool("msbuild", {envs = runenvs})
    local platform = is_arch("x64") and "x64" or "Win32"
    local projectdata = io.readfile(projectfile)
    if projectdata and projectdata:find("Any CPU", 1, true) then
        platform = "Any CPU"
    end
    os.vexecv(msbuild.program, {projectfile, "-nologo", "-t:Clean", "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"), "-p:Platform=" .. platform}, {envs = runenvs})
end

-- do build
function build()

    -- only support the current subsystem host platform now!
    assert(is_subhost(config.plat()), "msbuild: %s not supported!", config.plat())

    -- do build
    local projectfile = _find_projectfile()
    local runenvs = toolchain.load("msvc"):runenvs()
    local msbuild = find_tool("msbuild", {envs = runenvs})
    local platform = is_arch("x64") and "x64" or "Win32"
    local projectdata = io.readfile(projectfile)
    if projectdata and projectdata:find("Any CPU", 1, true) then
        platform = "Any CPU"
    end
    local configs = {projectfile, "-nologo", "-t:Build", "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"), "-p:Platform=" .. platform}
    local jobs = option.get("jobs") or tostring(os.default_njob())
    table.insert(configs, (jobs ~= nil and format("-m:%d", jobs) or "-m"))
    if jobs and project.policy("package.msbuild.multi_tool_task") then
        table.insert(configs, "/p:UseMultiToolTask=true")
        table.insert(configs, "/p:EnforceProcessCountAcrossBuilds=true")
        table.insert(configs, format("/p:MultiProcMaxCount=%d", jobs))
    end
    os.vexecv(msbuild.program, configs, {envs = runenvs})
    cprint("${color.success}build ok!")
end
