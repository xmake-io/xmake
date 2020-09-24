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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
        sdkdir = os.getenv("ANDROID_NDK_HOME") or os.getenv("ANDROID_NDK_ROOT")
        if not sdkdir and config.get("android_sdk") then
            sdkdir = path.join(config.get("android_sdk"), "ndk-bundle")
        end
        if not sdkdir and is_host("macosx") then
            sdkdir = "~/Library/Android/sdk/ndk-bundle"
        end
    end

    -- get ndk directory
    if sdkdir and os.isdir(sdkdir) then
        return path.translate(sdkdir)
    end
end

-- find the sdk version of ndk
function _find_ndk_sdkver(sdkdir, bindir, arch)

    -- uses llvm stl?
    local use_llvm = false
    local ndk_cxxstl = config.get("ndk_cxxstl")
    if ndk_cxxstl then
        -- we uses c++_static/c++_shared instead of llvmstl_static/llvmstl_shared
        if ndk_cxxstl:startswith("c++") or ndk_cxxstl:startswith("llvmstl") then
            use_llvm = true
        end
    elseif bindir and bindir:find("llvm", 1, true) then
        use_llvm = true
    end

    -- try to select the best compatible version
    local sdkver = "16"
    if use_llvm or arch == "arm64-v8a" then
        sdkver = "21"
    end
    if os.isdir(path.join(sdkdir, "platforms", "android-" .. sdkver)) then
        return sdkver
    end

    -- find the max version
    local sdkver_max = 0
    for _, sdkdir in ipairs(os.dirs(path.join(sdkdir, "platforms", "android-*"))) do

        -- get version
        local filename = path.filename(sdkdir)
        local version, count = filename:gsub("android%-", "")
        if count > 0 then

            -- get the max version
            local sdkver_now = tonumber(version)
            if sdkver_now > sdkver_max then
                sdkver_max = sdkver_now
            end
        end
    end

    -- get the max sdk version
    return sdkver_max > 0 and tostring(sdkver_max) or nil
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
        return
    end

    -- get cross
    local crosses =
    {
        ["armv5te"]     = "arm-linux-androideabi-" -- deprecated
    ,   ["armv7-a"]     = "arm-linux-androideabi-" -- deprecated
    ,   ["armeabi"]     = "arm-linux-androideabi-" -- removed in ndk r17
    ,   ["armeabi-v7a"] = "arm-linux-androideabi-"
    ,   ["arm64-v8a"]   = "aarch64-linux-android-"
    ,   i386            = "i686-linux-android-"    -- deprecated
    ,   x86             = "i686-linux-android-"
    ,   x86_64          = "x86_64-linux-android-"
    ,   mips            = "mips-linux-android-"    -- removed in ndk r17
    ,   mips64          = "mips64-linux-android-"  -- removed in ndk r17
    }
    local cross = crosses[arch]

    -- get gcc toolchain sub-directory
    local gcc_toolchain_subdirs =
    {
        ["armv5te"]     = "arm-linux-androideabi-*"
    ,   ["armv7-a"]     = "arm-linux-androideabi-*"
    ,   ["armeabi"]     = "arm-linux-androideabi-*"
    ,   ["armeabi-v7a"] = "arm-linux-androideabi-*"
    ,   ["arm64-v8a"]   = "aarch64-linux-android-*"
    ,   i386            = "x86-*"
    ,   x86             = "x86-*"
    ,   x86_64          = "x86_64-*"
    ,   mips            = "mipsel-linux-android-*"
    ,   mips64          = "mips64el-linux-android-*"
    }
    local gcc_toolchain_subdir = gcc_toolchain_subdirs[arch] or "arm-linux-androideabi-*"

    -- find the binary directory
    local bindir = find_directory("bin", path.join(sdkdir, "toolchains", "llvm", "prebuilt", "*")) -- larger than ndk r16
    if not bindir then
        bindir = find_directory("bin", path.join(sdkdir, "toolchains", gcc_toolchain_subdir, "prebuilt", "*"))
    end
    if not bindir then
        return
    end

    -- find the sdk version
    local sdkver = ndk_sdkver or _find_ndk_sdkver(sdkdir, bindir, arch)

    -- find the gcc toolchain
    local gcc_toolchain = find_directory("bin", path.join(sdkdir, "toolchains", gcc_toolchain_subdir, "prebuilt", "*"))
    if gcc_toolchain then
        gcc_toolchain = path.directory(gcc_toolchain)
    end

    -- find the toolchains version
    local toolchains_ver = ndk_toolchains_ver or _find_ndk_toolchains_ver(gcc_toolchain or bindir)

    -- get ndk version, e.g. r16b, ..
    local ndkver = nil
    local ndk_version_header = path.join(sdkdir, "sysroot/usr/include/android/ndk-version.h")
    if os.isfile(ndk_version_header) then
        local ndk_version_info = io.readfile(ndk_version_header)
        if ndk_version_info then
            ndk_version_info = ndk_version_info:match("#define __NDK_MAJOR__ (%d+)")
            if ndk_version_info then
                ndkver = tonumber(ndk_version_info)
            end
        end
    end

    -- ok?
    return {ndkver = ndkver, sdkdir = sdkdir, bindir = bindir, cross = cross, sdkver = sdkver, gcc_toolchain = gcc_toolchain, toolchains_ver = toolchains_ver}
end

-- find ndk toolchains
--
-- @param sdkdir    the ndk directory
-- @param opt       the argument options
--                  e.g. {arch = "[armeabi|armeabi-v7a|arm64-v8a]", verbose = true, force = false, sdkver = 19, toolchains_ver = "4.9"}
--
-- @return          the ndk toolchains. e.g. {bindir = .., cross = ..}
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
    local ndk = _find_ndk(sdkdir or config.get("ndk") or global.get("ndk"), arch, opt.sdkver or config.get("ndk_sdkver"), opt.toolchains_ver or config.get("ndk_toolchains_ver"))
    if ndk and ndk.sdkdir then

        -- save to config
        config.set("ndk", ndk.sdkdir, {force = true, readonly = true})
        config.set("ndkver", ndk.ndkver, {force = true, readonly = true})
        config.set("ndk_sdkver", ndk.sdkver, {force = true, readonly = true})
        config.set("ndk_toolchains_ver", ndk.toolchains_ver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for NDK directory ... ${color.success}%s", ndk.sdkdir)
            cprint("checking for SDK version of NDK ... ${color.success}%s", ndk.sdkver)
            cprint("checking for toolchains version of NDK ... ${color.success}%s", ndk.toolchains_ver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for NDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.ndk = ndk or false
    cache.save(key, cacheinfo)

    -- ok?
    return ndk
end
