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
        import("lib.detect.find_tool")
        import("detect.sdks.find_dotnet")

        -- find dotnet program
        local dotnet = find_tool("dotnet", {version = true})
        if not dotnet then
            return false
        end
        toolchain:config_set("dotnet", dotnet.program)
        toolchain:config_set("dotnet_version", dotnet.version)

        -- find dotnet sdk info
        local sdkinfo = find_dotnet()
        if sdkinfo then
            toolchain:config_set("sdkinfo", sdkinfo)
        end
        return true
    end)

    on_load(function (toolchain)
        local dotnet = toolchain:config("dotnet") or "dotnet"
        toolchain:set("toolset", "cs",   dotnet)
        toolchain:set("toolset", "csld", dotnet)
        toolchain:set("toolset", "cssh", dotnet)

        -- set default environment variables
        toolchain:add("runenvs", "DOTNET_NOLOGO", "1")
        toolchain:add("runenvs", "DOTNET_CLI_TELEMETRY_OPTOUT", "1")
        toolchain:add("runenvs", "DOTNET_SKIP_FIRST_TIME_EXPERIENCE", "1")
    end)
