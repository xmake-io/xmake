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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check_vstudio.lua
--

-- imports
import("core.base.option")
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")
import("core.platform.environment")

-- attempt to check vs environment
function _check_vsenv(config)

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
            local vsenv = vcvarsall[config.get("arch") or ""]
            if vsenv and vsenv.path and vsenv.include and vsenv.lib then

                -- save vsenv
                config.set("__vcvarsall", vcvarsall)

                -- check compiler
                environment.enter("toolchains")
                local program = nil
                local tool = find_tool("cl.exe", {force = true})
                if tool then
                    program = tool.program
                end
                environment.leave("toolchains")

                -- ok?
                if program then
                    return vsver
                end
            end
        end
    end
end

-- check the visual stdio
function main(config)

    -- attempt to check the given vs version first
    local vs = _check_vsenv(config)
    if vs then

        -- save it
        config.set("vs", vs, {readonly = true, force = true})

        -- trace
        print("checking for the Microsoft Visual Studio (%s) version ... %s", config.get("arch"), vs)
    else
        -- failed
        print("checking for the Microsoft Visual Studio (%s) version ... no", config.get("arch"))
        print("please run:")
        print("    - xmake config --vs=xxx [--vs_toolset=xxx]")
        print("or  - xmake global --vs=xxx")
        raise()
    end
end


