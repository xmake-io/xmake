--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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
-- @file        find_ndk.lua
--

-- imports
import("lib.detect.cache")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("lib.detect.find_directory")

-- find ndk directory
function _find_ndkdir(sdkdir)

    -- get ndk directory
    if not sdkdir then
        sdkdir = os.getenv("ANDROID_NDK_ROOT")
        if not sdkdir and is_host("macosx") then
            sdkdir = "~/Library/Android/sdk/ndk-bundle"
        end
    end

    -- get ndk directory
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
end

-- find the sdk version of ndk
function _find_ndk_sdkver(sdkdir)

    -- find the max version
    local sdkver_max = 0
    for _, sdkdir in ipairs(os.dirs(path.join(sdkdir, "platforms", "android-*"))) do

        -- get version
        local filename = path.filename(sdkdir)
        local version, count = filename:gsub("android%-", "")
        if count > 0 then

            -- get the max version
            local sdkver = tonumber(version)
            if sdkver > sdkver_max then
                sdkver_max = sdkver
            end
        end
    end

    -- get the max sdk version
    return sdkver_max > 0 and sdkver_max or nil
end

-- find the toolchains version of ndk
function _find_ndk_toolchains_ver(bindir)
    return bindir:match("%-(%d*%.%d*)[/\\]")
end

-- find the ndk toolchain
function _find_ndk(sdkdir, arch, ndk_sdkver, ndk_toolchains_ver)

    -- find ndk root directory
    sdkdir = _find_ndkdir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- is arm64?
    local arm64 = arch and arch:startswith("arm64")

    -- the cross
    local cross = arm64 and "aarch64-linux-android-" or "arm-linux-androideabi-"

    -- find the binary directory
    local bindir = find_directory("bin", path.join(sdkdir, "toolchains", "llvm", "prebuilt", "*")) -- larger than ndk r16
    if not bindir then
        bindir = find_directory("bin", path.join(sdkdir, "toolchains", cross .. "*", "prebuilt", "*"))
    end
    if not bindir then
        return {}
    end

    -- find the sdk version
    local sdkver = ndk_sdkver or _find_ndk_sdkver(sdkdir)
    if not sdkver then
        return {}
    end

    -- find the gcc toolchain
    local gcc_toolchain = find_directory("bin", path.join(sdkdir, "toolchains", cross .. "*", "prebuilt", "*"))
    if gcc_toolchain then
        gcc_toolchain = path.directory(gcc_toolchain)
    end

    -- find the toolchains version
    local toolchains_ver = ndk_toolchains_ver or _find_ndk_toolchains_ver(gcc_toolchain or bindir)
    if not toolchains_ver then
        return {}
    end

    -- ok?    
    return {sdkdir = sdkdir, bindir = bindir, cross = cross, sdkver = sdkver, gcc_toolchain = gcc_toolchain, toolchains_ver = toolchains_ver}
end

-- find ndk toolchains
--
-- @param sdkdir    the ndk directory
-- @param opt       the argument options 
--                  .e.g {arch = "[armv5te|armv6|armv7-a|armv8-a|arm64-v8a]", verbose = true, force = false, sdkver = 19, toolchains_ver = "4.9"}  
--
-- @return          the ndk toolchains. .e.g {bindir = .., cross = ..}
--
-- @code 
--
-- local toolchain = find_ndk("/xxx/android-ndk-r10e")
-- local toolchain = find_ndk("/xxx/android-ndk-r10e", {arch = "arm64-v8a"})
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_ndk"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.ndk and cacheinfo.ndk.sdkdir and os.isdir(cacheinfo.ndk.sdkdir) then
        return cacheinfo.ndk
    end

    -- get arch
    local arch = opt.arch or config.get("arch") or "armv7-a"
       
    -- find ndk
    local ndk = _find_ndk(sdkdir or config.get("ndk") or global.get("ndk") or config.get("sdk"), arch, opt.sdkver or config.get("ndk_sdkver"), opt.toolchains_ver or config.get("ndk_toolchains_ver"))
    if ndk and ndk.sdkdir then

        -- save to config
        config.set("ndk", ndk.sdkdir, {force = true, readonly = true})
        config.set("ndk_sdkver", ndk.sdkver, {force = true, readonly = true})
        config.set("ndk_toolchains_ver", ndk.toolchains_ver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the NDK directory ... ${color.success}%s", ndk.sdkdir)
            cprint("checking for the SDK version of NDK ... ${color.success}%s", ndk.sdkver)
            cprint("checking for the toolchains version of NDK ... ${color.success}%s", ndk.toolchains_ver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the NDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.ndk = ndk or false
    cache.save(key, cacheinfo)

    -- ok?
    return ndk
end
