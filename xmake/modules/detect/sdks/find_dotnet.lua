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
-- @file        find_dotnet.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("core.tool.toolchain")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")

-- find dotnet sdk info from dotnet cli
function _find_dotnet_cli(sdkdir)

    -- find dotnet program
    local paths = {}
    if sdkdir then
        table.insert(paths, path.join(sdkdir, "bin"))
        table.insert(paths, sdkdir)
    end
    local dotnet = find_tool("dotnet", {version = true, paths = #paths > 0 and paths or nil})
    if not dotnet then
        return nil
    end

    local bindir = path.directory(dotnet.program)
    local result = {bindir = bindir, version = dotnet.version}

    -- get sdk list, e.g. "8.0.100 [/usr/share/dotnet/sdk]"
    local sdklist = try { function () return os.iorunv(dotnet.program, {"--list-sdks"}) end }
    if sdklist then
        local sdks = {}
        for _, line in ipairs(sdklist:split("\n", {plain = true})) do
            line = line:trim()
            local ver, dir = line:match("^(%S+)%s+%[(.-)%]")
            if ver and dir then
                table.insert(sdks, {version = ver, directory = path.join(dir, ver)})
            end
        end
        if #sdks > 0 then
            result.sdks = sdks
            result.sdkdir = sdks[#sdks].directory
            result.sdkver = sdks[#sdks].version
        end
    end

    -- set sdkdir from bindir if not found from sdk list
    if not result.sdkdir then
        result.sdkdir = sdkdir or path.directory(bindir)
    end

    -- get runtime list, e.g. "Microsoft.NETCore.App 8.0.0 [/usr/share/dotnet/shared/Microsoft.NETCore.App]"
    local runtimelist = try { function () return os.iorunv(dotnet.program, {"--list-runtimes"}) end }
    if runtimelist then
        local runtimes = {}
        for _, line in ipairs(runtimelist:split("\n", {plain = true})) do
            line = line:trim()
            local name, ver = line:match("^(%S+)%s+(%S+)%s+%[")
            if name and ver then
                table.insert(runtimes, {name = name, version = ver})
            end
        end
        if #runtimes > 0 then
            result.runtimes = runtimes
        end
    end
    return result
end

-- find .NET Framework SDK directory from MSVC (Windows only)
function _find_netfxsdk(sdkdir)
    if not sdkdir then
        local msvc = toolchain.load("msvc")
        if msvc and msvc:check() then
            local vcvars = msvc:config("vcvars")
            if vcvars then
                sdkdir = vcvars.WindowsSdkDir
                if sdkdir then
                    sdkdir = path.join(path.directory(path.translate(sdkdir)), "NETFXSDK")
                end
            end
        end
    end
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get sdk version
    local sdkver
    local vers = {}
    for _, dir in ipairs(os.dirs(path.join(sdkdir, "*", "Include"))) do
        table.insert(vers, path.filename(path.directory(dir)))
    end
    for _, ver in ipairs(vers) do
        if os.isdir(path.join(sdkdir, ver, "Lib", "um")) and os.isdir(path.join(sdkdir, ver, "Include", "um")) then
            sdkver = ver
            break
        end
    end
    if not sdkver then
        return nil
    end
    return {sdkdir = sdkdir, sdkver = sdkver,
        libdir = path.join(sdkdir, sdkver, "Lib"),
        includedir = path.join(sdkdir, sdkver, "Include")}
end

-- find dotnet sdk
--
-- @param sdkdir    the dotnet directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the dotnet sdk info, e.g. {program = ..., version = ..., sdkver = ..., sdkdir = ..., sdks = {...}, runtimes = {...}}
--
-- @code
--
-- local dotnet = find_dotnet()
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_dotnet"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.dotnet and cacheinfo.dotnet.sdkdir and os.isdir(cacheinfo.dotnet.sdkdir) then
        return cacheinfo.dotnet
    end

    -- find dotnet cli sdk
    local dotnet = _find_dotnet_cli(sdkdir or config.get("dotnet") or global.get("dotnet"))

    -- find .NET Framework SDK on Windows
    if is_host("windows") then
        local netfxsdk = _find_netfxsdk(sdkdir or config.get("dotnet") or global.get("dotnet"))
        if netfxsdk then
            if dotnet then
                dotnet.netfxsdk = netfxsdk
            else
                dotnet = netfxsdk
            end
        end
    end

    if dotnet then

        -- save to config
        if dotnet.sdkdir then
            config.set("dotnet", dotnet.sdkdir, {force = true, readonly = true})
        end
        if dotnet.sdkver then
            config.set("dotnet_sdkver", dotnet.sdkver, {force = true, readonly = true})
        end

        -- trace
        if opt.verbose or option.get("verbose") then
            if dotnet.version then
                cprint("checking for .NET SDK version ... ${color.success}%s", dotnet.version)
            end
            if dotnet.sdkdir then
                cprint("checking for .NET SDK directory ... ${color.success}%s", dotnet.sdkdir)
            end
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for .NET SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.dotnet = dotnet or false
    detectcache:set(key, cacheinfo)
    return dotnet
end
