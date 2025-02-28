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
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")

function _find_clang_cl(vcvars)
    local paths
    local pathenv = os.getenv("PATH")
    if pathenv then
        paths = path.splitenv(pathenv)
    end
    return find_tool("clang-cl", {version = true, force = true, paths = paths, envs = vcvars})
end

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
                local tool = _find_clang_cl(vcvars)
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
    local vs, clang_cl = _check_vsenv(toolchain)
    if vs then
        if toolchain:is_global() then
            config.set("vs", vs, {force = true, readonly = true})
        end
        toolchain:config_set("vs", vs)
        toolchain:configs_save()
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.success}%s", toolchain:arch(), vs)
        if clang_cl and clang_cl.version then
            cprint("checking for LLVM Clang C/C++ Compiler (%s) version ... ${color.success}%s", toolchain:arch(), clang_cl.version)
        end
    else
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.nothing}${text.nothing}", toolchain:arch())
    end
    return vs
end

function _check_vc_build_tools(toolchain, sdkdir)
    local opt = {}
    opt.sdkdir = sdkdir
    opt.vs_toolset = toolchain:config("vs_toolset") or config.get("vs_toolset")
    opt.vs_sdkver = toolchain:config("vs_sdkver") or config.get("vs_sdkver")

    local vcvarsall = find_vstudio.find_build_tools(opt)
    if not vcvarsall then
        return
    end

    local vcvars = vcvarsall[toolchain:arch()]
    if vcvars and vcvars.PATH and vcvars.INCLUDE and vcvars.LIB then
        -- save vcvars
        toolchain:config_set("vcvars", vcvars)
        toolchain:config_set("vcarchs", table.orderkeys(vcvarsall))
        toolchain:config_set("vs_toolset", vcvars.VCToolsVersion)
        toolchain:config_set("vs_sdkver", vcvars.WindowsSDKVersion)

        -- check compiler
        local clang_cl = _find_clang_cl(vcvars)
        if clang_cl and clang_cl.version then
            cprint("checking for LLVM Clang C/C++ Compiler (%s) version ... ${color.success}%s", toolchain:arch(), clang_cl.version)
        end
        return vcvars
    end
end

function main(toolchain)

    -- only for windows or linux (msvc-wine)
    if not is_host("windows", "linux") then
        return
    end

    -- @see https://github.com/xmake-io/xmake/pull/679
    local cc  = path.basename(config.get("cc") or "clang-cl"):lower()
    local cxx = path.basename(config.get("cxx") or "clang-cl"):lower()
    local mrc = path.basename(config.get("mrc") or "rc"):lower()
    if cc == "clang-cl" or cxx == "clang-cl" or mrc == "rc" then
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            return _check_vc_build_tools(toolchain, sdkdir)
        else
            -- find it from packages
            for _, package in ipairs(toolchain:packages()) do
                local installdir = package:installdir()
                if installdir and os.isdir(installdir) then
                    local result = _check_vc_build_tools(toolchain, installdir)
                    if result then
                        return result
                    end
                end
            end

            -- find it from system
            return _check_vstudio(toolchain)
        end
    end
end

