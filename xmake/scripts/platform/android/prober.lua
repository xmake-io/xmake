--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        prober.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local tools     = require("tools/tools")
local config    = require("base/config")
local global    = require("base/global")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch(configs)

    -- get the architecture
    local arch = configs.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    configs.set("arch", "armv7-a")

    -- trace
    utils.verbose("checking for the architecture ... %s", configs.get("arch"))

    -- ok
    return true
end

-- probe the sdk version for ndk
function prober._probe_ndk_sdkver(configs)

    -- ok?
    local ndk_sdkver = config.get("ndk_sdkver")
    if ndk_sdkver then return true end

    -- get the ndk
    local ndk = config.get("ndk")
    if ndk then

        -- match all sdk directories
        local sdkdirs = os.match(ndk .. "/platforms/android-*", true)
        if sdkdirs then
            
            -- get the max version
            local version_maxn = 0
            for _, sdkdir in ipairs(sdkdirs) do
                local filename = path.filename(sdkdir)
                local version, count = filename:gsub("android%-", "")
                if count > 0 then
                    version = tonumber(version)
                    if version > version_maxn then version_maxn = version end
                end
            end

            -- save the version
            if version_maxn > 0 then ndk_sdkver = version_maxn end
        end
    end

    -- probe ok? update it
    if ndk_sdkver > 0 then 
        configs.set("ndk_sdkver", ndk_sdkver)
        configs.set("__ndk_sdkdir", string.format("%s/platforms/android-%d", ndk, ndk_sdkver))
    end

    -- trace
    utils.verbose("checking for the SDK version of NDK ... %s", string.format("android-%d", ndk_sdkver))

    -- ok
    return true
end

-- probe the ccache
function prober._probe_ccache(configs)

    -- ok? 
    local ccache_enable = configs.get("ccache")
    if ccache_enable and configs.get("__ccache") then return true end

    -- disable?
    if type(ccache_enable) == "boolean" and not ccache_enable then
        configs.set("__ccache", nil)
        return true
    end

    -- probe the ccache path
    local ccache_path = tools.probe("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

    -- probe ok? update it
    if ccache_path then
        configs.set("ccache", true)
        configs.set("__ccache", ccache_path)
    else
        configs.set("ccache", false)
    end

    -- trace
    utils.verbose("checking for the ccache ... %s", utils.ifelse(ccache_path, ccache_path, "no"))

    -- ok
    return true
end

-- probe the toolchains
function prober._probe_toolpath(configs, kind, cross, name, description)

    -- check
    assert(kind)

    -- get the cross
    cross = config.get("cross") or cross

    -- attempt to get it from the given cross toolchains
    local toolpath = nil
    local toolchains = config.get("toolchains") 
    if toolchains then
        toolpath = tools.probe(cross .. (config.get(kind) or name), toolchains)
    end

    -- attempt to get it directly from the configure
    if not toolpath then
        toolpath = config.get(kind)
    end

    -- attempt to get it from the ndk
    if not toolpath then
        local ndk = config.get("ndk")
        if ndk then

            -- match all toolchains
            toolchains = os.match(string.format("%s/toolchains/arm-linux-androideabi-**/prebuilt/*/bin/%s%s", ndk, cross, name))
            if toolchains then
                for _, filepath in ipairs(toolchains) do
                    -- probe the tool path
                    toolpath = tools.probe(cross .. name, path.directory(filepath))
                    if toolpath then break end
                end
            end
        end
    end

    -- probe ok? update it
    if toolpath then configs.set(kind, toolpath) end

    -- trace
    utils.verbose("checking for %s (%s) ... %s", description, kind, utils.ifelse(toolpath, path.filename(toolpath), "no"))

    -- ok
    return true
end

-- probe the compiler
function prober._probe_toolchains(configs)

    -- done
    if not prober._probe_toolpath(configs, "cc", "arm-linux-androideabi-", "gcc", "the c compiler") then return false end
    if not prober._probe_toolpath(configs, "cxx", "arm-linux-androideabi-", "g++", "the c++ compiler") then return false end
    if not prober._probe_toolpath(configs, "as", "arm-linux-androideabi-", "gcc", "the assember") then return false end
    if not prober._probe_toolpath(configs, "ld", "arm-linux-androideabi-", "g++", "the linker") then return false end
    if not prober._probe_toolpath(configs, "ar", "arm-linux-androideabi-", "ar", "the static library linker") then return false end
    if not prober._probe_toolpath(configs, "sh", "arm-linux-androideabi-", "g++", "the shared library linker") then return false end
    return true
end

-- probe the project configure 
function prober.config()

    -- call all probe functions
    utils.call(     {   prober._probe_arch
                    ,   prober._probe_ccache
                    ,   prober._probe_ndk_sdkver
                    ,   prober._probe_toolchains}
                ,   nil
                ,   config)

end

-- probe the global configure 
function prober.global()

    -- call all probe functions
    utils.call(     {   prober._probe_ccache
                    ,   prober._probe_ndk_sdkver}
                ,   nil
                ,   global)
end

-- return module: prober
return prober
