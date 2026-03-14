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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

toolchain("dotnet")
    set_kind("standalone")
    set_homepage("https://dotnet.microsoft.com/")
    set_description(".NET SDK Toolchain")

    set_toolset("cs",   "dotnet")
    set_toolset("csld", "dotnet")
    set_toolset("cssh", "dotnet")

    on_check(function (toolchain)
        import("detect.sdks.find_dotnet")

        -- find dotnet sdk from packages first
        local sdkinfo
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir and os.isdir(installdir) then
                sdkinfo = find_dotnet(installdir, {force = true})
                if sdkinfo then
                    break
                end
            end
        end

        -- find dotnet sdk from system
        if not sdkinfo then
            sdkinfo = find_dotnet()
        end
        if not sdkinfo or not sdkinfo.bindir then
            return false
        end
        toolchain:config_set("bindir", sdkinfo.bindir)
        toolchain:config_set("sdkdir", sdkinfo.sdkdir)
        return true
    end)

    on_load(function (toolchain)

        -- set default environment variables
        toolchain:add("runenvs", "DOTNET_NOLOGO", "1")
        toolchain:add("runenvs", "DOTNET_CLI_TELEMETRY_OPTOUT", "1")
        toolchain:add("runenvs", "DOTNET_SKIP_FIRST_TIME_EXPERIENCE", "1")
    end)
