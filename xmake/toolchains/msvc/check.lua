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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")

-- attempt to check vs environment
function _check_vsenv(toolchain)

    -- have been checked?
    local vs = config.get("vs")
    if vs and config.get("__vcvarsall") then
        return vs
    end

    -- find vstudio
    local vstudio = find_vstudio({vcvars_ver = config.get("vs_toolset"), sdkver = config.get("vs_sdkver")})
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
            local vsenv = vcvarsall[toolchain:arch()]
            if vsenv and vsenv.PATH and vsenv.INCLUDE and vsenv.LIB then

                -- save vsenv
                config.set("__vcvarsall", vcvarsall)

                -- check compiler
                local program = nil
                local tool = find_tool("cl.exe", {force = true, envs = vsenv})
                if tool then
                    program = tool.program
                end
                if program then
                    return vsver
                end
            end
        end
    end
end

-- check the visual studio
function _check_vstudio(toolchain)
    local vs = _check_vsenv(toolchain)
    if vs then
        config.set("vs", vs, {readonly = true, force = true})
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.success}%s", toolchain:arch(), vs)
    else
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.nothing}${text.nothing}", toolchain:arch())
        if not (opt and opt.try) then
            print("please run:")
            print("    - xmake config --vs=xxx [--vs_toolset=xxx]")
            print("or  - xmake global --vs=xxx")
            raise()
        end
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

