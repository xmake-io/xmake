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
import("core.base.semver")
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")

-- attempt to check vs environment
function _check_vsenv(toolchain)

    -- have been checked?
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
    local vstudio = find_vstudio({vcvars_ver = vs_toolset, sdkver = vs_sdkver})
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
                local program = nil
                local tool = find_tool("cl.exe", {version = true, force = true, envs = vcvars})
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
    local vs, msvc = _check_vsenv(toolchain)
    if vs then
        if toolchain:is_global() then
            config.set("vs", vs, {force = true, readonly = true})
        end
        toolchain:config_set("vs", vs)
        if vs == "6.0" then
            toolchain:config_set("vs_toolset", "6.0")
        end
        local vs_toolset = toolchain:config("vs_toolset")
        if semver.is_valid(vs_toolset) and semver.compare(vs_toolset, "8.0") < 0 then
            toolchain:config_set("vs_unicode", false)
        else
            toolchain:config_set("vs_unicode", true)
        end
        toolchain:configs_save()
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.success}%s", toolchain:arch(), vs)
        if msvc and msvc.version then
            cprint("checking for Microsoft C/C++ Compiler (%s) version ... ${color.success}%s", toolchain:arch(), msvc.version)
        end
    else
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.nothing}${text.nothing}", toolchain:arch())
    end
    return vs
end

-- main entry
function main(toolchain)

    -- only for windows
    if not is_host("windows") then
        return
    end

    -- @see https://github.com/xmake-io/xmake/pull/679
    local cc  = path.basename(config.get("cc") or "cl"):lower()
    local cxx = path.basename(config.get("cxx") or "cl"):lower()
    local mrc = path.basename(config.get("mrc") or "rc"):lower()
    if cc == "cl" or cxx == "cl" or mrc == "rc" then
        return _check_vstudio(toolchain)
    end
end

