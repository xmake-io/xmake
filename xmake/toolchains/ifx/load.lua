--!A cross-toolchain build utility based on Lua
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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_vstudio")

-- add the given vs environment
function _add_vsenv(toolchain, name, curenvs)

    -- get vcvars
    local vcvars = toolchain:config("vcvars")
    if not vcvars then
        return
    end

    -- get the paths for the vs environment
    local new = vcvars[name]
    if new then
        -- fix case naming conflict for cmake/msbuild between the new msvc envs and current environment, if we are running xmake in vs prompt.
        -- @see https://github.com/xmake-io/xmake/issues/4751
        for k, c in pairs(curenvs) do
            if name:lower() == k:lower() and name ~= k then
                name = k
                break
            end
        end
        toolchain:add("runenvs", name, table.unpack(path.splitenv(new)))
    end
end

-- add the given ifx environment
function _add_ifxenv(toolchain, name, curenvs)

    -- get ifxvarsall
    local ifxvarsall = toolchain:config("varsall")
    if not ifxvarsall then
        return
    end

    -- get ifx environment for the current arch
    local arch = toolchain:arch()
    local ifxenv = ifxvarsall[arch] or {}

    -- get the paths for the ifx environment
    local new = ifxenv[name]
    if new then
        -- fix case naming conflict for cmake/msbuild between the new msvc envs and current environment, if we are running xmake in vs prompt.
        -- @see https://github.com/xmake-io/xmake/issues/4751
        for k, c in pairs(curenvs) do
            if name:lower() == k:lower() and name ~= k then
                name = k
                break
            end
        end
        toolchain:add("runenvs", name, table.unpack(path.splitenv(new)))
    end
end

-- load intel on windows
function _load_intel_on_windows(toolchain)

    -- set toolset
    toolchain:set("toolset", "fc", "ifx.exe")
    toolchain:set("toolset", "mrc", "rc.exe")
    if toolchain:is_arch("x64") then
        toolchain:set("toolset", "as",  "ml64.exe")
    else
        toolchain:set("toolset", "as",  "ml.exe")
    end
    toolchain:set("toolset", "fcld",  "ifx.exe")
    toolchain:set("toolset", "fcsh",  "ifx.exe")
    toolchain:set("toolset", "ar",  "link.exe")

    -- add vs/ifx environments
    local expect_vars = {"PATH", "LIB", "INCLUDE", "LIBPATH"}
    local curenvs = os.getenvs()
    for _, name in ipairs(expect_vars) do
        _add_vsenv(toolchain, name, curenvs)
        _add_ifxenv(toolchain, name, curenvs)
    end
    for _, name in ipairs(find_vstudio.get_vcvars()) do
        if not table.contains(expect_vars, name:upper()) then
            _add_vsenv(toolchain, name, curenvs)
        end
    end
end

-- load intel on linux
function _load_intel_on_linux(toolchain)

    -- set toolset
    toolchain:set("toolset", "fc", "ifx")
    toolchain:set("toolset", "fcld", "ifx")
    toolchain:set("toolset", "fcsh", "ifx")
    toolchain:set("toolset", "ar", "ar")

    -- add march flags
    local march
    if toolchain:is_arch("x86_64", "x64") then
        march = "-m64"
    elseif toolchain:is_arch("i386", "x86") then
        march = "-m32"
    end
    if march then
        toolchain:add("fcflags", march)
        toolchain:add("fcldflags", march)
        toolchain:add("fcshflags", march)
    end

    -- get ifx environments
    local ifxenv = toolchain:config("ifxenv")
    if ifxenv then
        local ldname = is_host("macosx") and "DYLD_LIBRARY_PATH" or "LD_LIBRARY_PATH"
        toolchain:add("runenvs", ldname, ifxenv.libdir)
    end
end

-- main entry
function main(toolchain)
    if is_host("windows") then
        return _load_intel_on_windows(toolchain)
    else
        return _load_intel_on_linux(toolchain)
    end
end

