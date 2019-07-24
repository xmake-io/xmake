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
-- @file        find_xcode.lua
--

-- imports
import("lib.detect.cache")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("lib.detect.find_directory")

-- find xcode directory
function _find_sdkdir(sdkdir)
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
    return find_directory("Xcode.app", {"/Applications"}) or find_directory("Xcode*.app", {"/Applications"})
end

-- find the sdk version of xcode
function _find_xcode_sdkver(sdkdir, plat, arch)

    -- select platform sdkdir
    local platsdkdir = nil
    if plat == "iphoneos" then
        if arch == "i386" or arch == "x86_64" then
            platsdkdir = "Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.*.sdk"
        else
            platsdkdir = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.*.sdk"
        end
    elseif plat == "watchos" then
        if arch == "i386" or arch == "x86_64" then
            platsdkdir = "Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator*.*.sdk"
        else
            platsdkdir = "Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS*.*.sdk"
        end
    else
        platsdkdir = "Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.*.sdk"
    end

    -- attempt to find the platform directory and get sdk version
    if platsdkdir then
	    local dir = find_directory(platsdkdir, sdkdir)
        if dir then
            return dir:match("%d+%.%d+")
        end
    end
end

-- find the xcode toolchain
function _find_xcode(sdkdir, xcode_sdkver, plat, arch)

    -- find xcode root directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- find the sdk version
    local sdkver = xcode_sdkver or _find_xcode_sdkver(sdkdir, plat, arch)
    if not sdkver then
        return {}
    end

    -- ok?    
    return {sdkdir = sdkdir, sdkver = sdkver}
end

-- find xcode toolchain
--
-- @param sdkdir    the xcode directory
-- @param opt       the argument options 
--                  e.g. {verbose = true, force = false, sdkver = 19, toolchains_ver = "4.9"}  
--
-- @return          the xcode toolchain. e.g. {bindir = .., cross = ..}
--
-- @code 
--
-- local toolchain = find_xcode("/Applications/Xcode.app")
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_xcode"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.xcode and cacheinfo.xcode.sdkdir and os.isdir(cacheinfo.xcode.sdkdir) then
        return cacheinfo.xcode
    end

    -- get plat and arch
    local plat = opt.plat or config.get("plat") or "macosx"
    local arch = opt.arch or config.get("arch") or "x86_64"

    -- find xcode
    local xcode = _find_xcode(sdkdir or config.get("xcode") or global.get("xcode") or config.get("sdk"), opt.sdkver or config.get("xcode_sdkver"), plat, arch)
    if xcode and xcode.sdkdir then

        -- save to config
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
        config.set("xcode_sdkver", xcode.sdkver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Xcode directory ... ${color.success}%s", xcode.sdkdir)
            cprint("checking for the SDK version of Xcode ... ${color.success}%s", xcode.sdkver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Xcode directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.xcode = xcode or false
    cache.save(key, cacheinfo)

    -- ok?
    return xcode
end
