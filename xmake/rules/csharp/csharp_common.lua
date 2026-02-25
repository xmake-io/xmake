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
-- @author      JassJam
-- @file        csharp_common.lua
--

import("core.base.option")

function _map_rid_arch(arch)
    arch = (arch or ""):lower()
    if arch == "x64" or arch == "x86_64" or arch == "amd64" then
        return "x64"
    elseif arch == "x86" or arch == "i386" then
        return "x86"
    elseif arch == "arm64" then
        return "arm64"
    elseif arch == "arm" or arch == "armv7" then
        return "arm"
    elseif arch == "riscv64" then
        return "riscv64"
    end
    return nil
end

function find_csproj(target)
    local csproj = target:data("csharp.csproj")
    if csproj then
        return csproj
    end
    for _, sourcefile in ipairs(target:sourcefiles()) do
        if path.extension(sourcefile):lower() == ".csproj" then
            local csprojabs = path.is_absolute(sourcefile) and sourcefile or path.absolute(sourcefile, os.projectdir())
            if os.isfile(csprojabs) then
                return csprojabs
            end
        end
    end
    return nil
end

function build_mode_to_configuration()
    local mode
    if type(get_config) == "function" then
        mode = get_config("mode")
    end
    if not mode and type(is_mode) == "function" then
        if is_mode("debug") then
            mode = "debug"
        elseif is_mode("release") then
            mode = "release"
        end
    end
    mode = mode or "release"
    local mode_lower = mode:lower()
    if mode_lower == "debug" then
        return "Debug"
    elseif mode_lower == "release" then
        return "Release"
    end
    return mode:sub(1, 1):upper() .. mode:sub(2)
end

function get_runtime_identifier(target)
    local rid = target:values("csharp.runtime_identifier")
    if type(rid) == "table" then
        rid = rid[1]
    end
    if rid and #rid > 0 then
        return rid
    end
    local arch = _map_rid_arch(target:arch())
    if not arch then
        return nil
    end
    local plat = target:plat()
    if plat == "windows" or plat == "mingw" or plat == "msys" or plat == "cygwin" then
        return "win-" .. arch
    elseif plat == "linux" then
        return "linux-" .. arch
    elseif plat == "macosx" then
        return "osx-" .. arch
    end
    return nil
end

function append_target_flags(target, argv)
    local flags = {}
    table.join2(flags, table.wrap(target:get("csflags")))
    table.join2(flags, table.wrap(target:get("ldflags")))
    table.join2(flags, table.wrap(target:get("arflags")))
    table.join2(flags, table.wrap(target:get("shflags")))
    for _, flag in ipairs(flags) do
        if flag and #flag > 0 then
            table.insert(argv, flag)
        end
    end
end

function get_dotnet_runopt(csprojfile)
    return {
        curdir = path.directory(csprojfile),
        envs = {
            DOTNET_NOLOGO = "1",
            DOTNET_CLI_TELEMETRY_OPTOUT = "1",
            DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1",
            DOTNET_GENERATE_ASPNET_CERTIFICATE = "0",
            DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = "0"
        }
    }
end

function get_dotnet_verbosity()
    if option.get("diagnosis") then
        return "diagnostic"
    end
    return "quiet"
end

function get_dotnet_program(target)
    local function _get_configured_program(toolkind)
        if target:get("toolset." .. toolkind) then
            local program = target:tool(toolkind)
            if program and #program > 0 then
                return program
            end
        end
    end

    local program = nil
    if target:is_binary() then
        program = _get_configured_program("ld")
    elseif target:is_shared() then
        program = _get_configured_program("sh")
    else
        program = _get_configured_program("cs")
    end
    if program then
        return program
    end

    program = target:tool("cs")
    if program and #program > 0 then
        return program
    end
    return "dotnet"
end
