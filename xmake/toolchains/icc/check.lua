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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_iccenv")
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")

-- attempt to check vs environment
function _check_vsenv(toolchain)

    -- has been checked?
    local vs = toolchain:config("vs") or config.get("vs")
    if vs then
        vs = tostring(vs)
    end
    local vcvars = toolchain:config("vcvars")
    if vs and vcvars then
        return vs
    end

    -- find vstudio
    local vs_toolset = toolchain:config("vs_toolset") or config.get("vs_toolset")
    local vs_sdkver  = toolchain:config("vs_sdkver") or config.get("vs_sdkver")
    local vstudio = find_vstudio({toolset = vs_toolset, sdkver = vs_sdkver})
    if vstudio then

        -- make order vsver
        local vsvers = {}
        for vsver, _ in pairs(vstudio) do
            if not vs or vs ~= vsver then
                table.insert(vsvers, vsver)
            end
        end
        table.sort(vsvers, function (a, b) return tonumber(a) > tonumber(b) end)
        if vs then
            table.insert(vsvers, 1, vs)
        end

        -- get vcvarsall
        for _, vsver in ipairs(vsvers) do
            local vcvarsall = (vstudio[vsver] or {}).vcvarsall or {}
            local vcvars = vcvarsall[toolchain:arch()]
            if vcvars and vcvars.PATH and vcvars.INCLUDE and vcvars.LIB then

                -- save vcvars
                toolchain:config_set("vcvars", vcvars)
                toolchain:config_set("vcarchs", table.orderkeys(vcvarsall))
                toolchain:config_set("vs_toolset", vcvars.VCToolsVersion)
                toolchain:config_set("vs_sdkver", vcvars.WindowsSDKVersion)

                -- check compiler
                local program
                local paths
                local pathenv = os.getenv("PATH")
                if pathenv then
                    paths = path.splitenv(pathenv)
                end
                local tool = find_tool("cl.exe", {version = true, force = true, paths = paths, envs = vcvars})
                if tool then
                    program = tool.program
                end
                if program then
                    return vsver, tool
                end
            end
        end
    end
end

-- check the visual studio
function _check_vstudio(toolchain)
    local vs = _check_vsenv(toolchain)
    if vs then
        if toolchain:is_global() then
            config.set("vs", vs, {force = true, readonly = true})
        end
        toolchain:config_set("vs", vs)
        toolchain:configs_save()
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.success}%s", toolchain:arch(), vs)
    else
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.nothing}${text.nothing}", toolchain:arch())
    end
    return vs
end

-- check intel on windows
function _check_intel_on_windows(toolchain)

    -- have been checked?
    local varsall = toolchain:config("varsall")
    if varsall then
        return true
    end

    -- find intel c/c++ compiler environment
    local iccenv = find_iccenv()
    if iccenv and iccenv.iclvars then
        local iclvarsall = iccenv.iclvars
        local iclenv = iclvarsall[toolchain:arch()]
        if iclenv and iclenv.PATH and iclenv.INCLUDE and iclenv.LIB then
            local tool = find_tool("icl.exe", {force = true, envs = iclenv, version = true})
            if tool then
                cprint("checking for Intel C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
                toolchain:config_set("varsall", iclvarsall)
                toolchain:configs_save()
                return _check_vstudio(toolchain)
            end
        end
    end
end

-- check intel on linux
function _check_intel_on_linux(toolchain)
    local iccenv = toolchain:config("iccenv")
    if iccenv then
        return true
    end
    iccenv = find_iccenv()
    if iccenv then
        local ldname = is_host("macosx") and "DYLD_LIBRARY_PATH" or "LD_LIBRARY_PATH"
        local tool = find_tool("icc", {force = true, envs = {[ldname] = iccenv.libdir}, paths = iccenv.bindir})
        if tool then
            cprint("checking for Intel C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
            toolchain:config_set("iccenv", iccenv)
            toolchain:config_set("bindir", iccenv.bindir)
            toolchain:configs_save()
            return true
        end
        return true
    end
end

-- main entry
function main(toolchain)
    if is_host("windows") then
        return _check_intel_on_windows(toolchain)
    else
        return _check_intel_on_linux(toolchain)
    end
end

