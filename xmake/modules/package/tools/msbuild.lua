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
import("lib.detect.find_tool")
import("private.utils.upgrade_vsproj")
import("private.utils.toolchain", {alias = "toolchain_utils"})

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

-- get msvc run environments
function _get_msvc_runenvs(package)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- get vs arch
function _get_vsarch(package)
    local arch = package:arch()
    if arch == 'x86' or arch == 'i386' then return "Win32" end
    if arch == 'x86_64' then return "x64" end
    if arch:startswith('arm64') then return "ARM64" end
    if arch:startswith('arm') then return "ARM" end
    return arch
end

-- get configs
function _get_configs(package, configs, opt)
    local jobs = _get_parallel_njobs(opt)
    configs = configs or {}
    local configs_str = string.serialize(configs, {indent = false, strip = true})
    table.insert(configs, "-nologo")
    table.insert(configs, (jobs ~= nil and format("-m:%d", jobs) or "-m"))
    if not configs_str:find("p:Configuration=", 1, true) then
        table.insert(configs, "-p:Configuration=" .. (package:is_debug() and "Debug" or "Release"))
    end
    if not configs_str:find("p:Platform=", 1, true) then
        table.insert(configs, "-p:Platform=" .. _get_vsarch(package))
    end
    if not configs_str:find("p:PlatformToolset=", 1, true) then
        local vs_toolset = toolchain_utils.get_vs_toolset_ver(_get_msvc(package):config("vs_toolset") or config.get("vs_toolset"))
        if vs_toolset then
            table.insert(configs, "/p:PlatformToolset=" .. vs_toolset)
        end
    end
    if project.policy("package.msbuild.multi_tool_task") or package:policy("package.msbuild.multi_tool_task") then
        table.insert(configs, "/p:UseMultiToolTask=true")
        table.insert(configs, "/p:EnforceProcessCountAcrossBuilds=true")
        if jobs then
            table.insert(configs, format("/p:MultiProcMaxCount=%d", jobs))
        end
    end
    return configs
end

-- get the build environments
function buildenvs(package, opt)
    return _get_msvc_runenvs(package)
end

-- build package
function build(package, configs, opt)
    opt = opt or {}

    -- pass configurations
    local argv = {}
    for name, value in pairs(_get_configs(package, configs, opt)) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(argv, value)
            else
                table.insert(argv, name .. "=" .. value)
            end
        end
    end

    -- upgrade vs solution file?
    -- @see https://github.com/xmake-io/xmake/issues/3871
    if opt.upgrade then
        local msvc = _get_msvc(package)
        for _, value in ipairs(opt.upgrade) do
            upgrade_vsproj.upgrade(value, table.join(opt, {msvc = msvc}))
        end
    end

    -- do build
    local envs = opt.envs or buildenvs(package, opt)
    local msbuild = find_tool("msbuild", {envs = envs})
    os.vrunv(msbuild.program, argv, {envs = envs})
end
