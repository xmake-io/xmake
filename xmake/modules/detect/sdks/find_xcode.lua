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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_xcode.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_directory")
import("private.tools.codesign")

-- find xcode directory
function _find_sdkdir(sdkdir, opt)
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
    return find_directory("Xcode.app", {"/Applications"}) or find_directory("Xcode*.app", {"/Applications"})
end

-- find the sdk version of xcode
function _find_xcode_sdkver(sdkdir, opt)

    -- select platform sdkdir
    local plat = opt.plat
    local arch = opt.arch
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
    elseif plat == "appletvos" then
        if arch == "i386" or arch == "x86_64" then
            platsdkdir = "Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator*.*.sdk"
        else
            platsdkdir = "Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS*.*.sdk"
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

-- find the target minver
function _find_target_minver(sdkdir, sdkver, opt)
    opt = opt or {}
    local target_minver = sdkver
    if opt.plat == "macosx" then
        if opt.appledev == "catalyst" then
            local platsdkdir = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.*.sdk"
            local dir = find_directory(platsdkdir, sdkdir)
            if dir then
                target_minver = dir:match("%d+%.%d+")
            else
                target_minver = "13.1"
            end
        else
            local macos_ver = macos.version()
            if macos_ver and (not sdkver or macos_ver:le(sdkver)) then
                target_minver = macos_ver:major() .. "." .. macos_ver:minor()
            end
        end
    end
    return target_minver
end

-- find the xcode toolchain
function _find_xcode(sdkdir, opt)

    -- find xcode root directory
    sdkdir = _find_sdkdir(sdkdir, opt)
    if not sdkdir then
        return {}
    end

    -- find the sdk version
    local sdkver = opt.sdkver or _find_xcode_sdkver(sdkdir, opt)
    if not sdkver then
        return {}
    end

    -- find the target minver
    local target_minver = _find_target_minver(sdkdir, sdkver, opt)

    -- find codesign
    local codesign_identity, mobile_provision
    if opt.find_codesign then

        -- find codesign identity
        codesign_identity = config.get("xcode_codesign_identity")
        if codesign_identity == nil then -- we will disable codesign_identity if be false
            codesign_identity = global.get("xcode_codesign_identity")
        end
        if codesign_identity == nil then
            local codesign_identities = codesign.codesign_identities()
            if codesign_identities then
                for identity, _ in pairs(codesign_identities) do
                    codesign_identity = identity
                    break
                end
            end
        end

        -- find mobile provision only for iphoneos
        if opt.plat == "iphoneos" then
            local mobile_provisions = codesign.mobile_provisions()
            if mobile_provisions then
                mobile_provision = config.get("xcode_mobile_provision")
                if mobile_provision == nil then -- we will disable mobile_provision if be false
                    mobile_provision = global.get("xcode_mobile_provision")
                end
                if mobile_provision == nil then
                    for provision, _ in pairs(mobile_provisions) do
                        mobile_provision = provision
                        break
                    end
                -- valid mobile provision not found? reset it
                elseif not mobile_provisions[mobile_provision] then
                    mobile_provision = nil
                end
            end
        end
    end
    return {sdkdir = sdkdir, sdkver = sdkver, target_minver = target_minver, codesign_identity = codesign_identity, mobile_provision = mobile_provision}
end

-- find xcode toolchain
--
-- @param sdkdir    the xcode directory
-- @param opt       the argument options
--                  e.g. {verbose = true, force = false, sdkver = 19, find_codesign = true}
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
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.xcode and cacheinfo.xcode.sdkdir and os.isdir(cacheinfo.xcode.sdkdir) then
        return cacheinfo.xcode
    end

    -- get plat and arch
    local plat = opt.plat or config.get("plat") or os.host()
    local arch = opt.arch or config.get("arch") or os.arch()

    -- find xcode
    local xcode = _find_xcode(sdkdir or config.get("xcode") or global.get("xcode"), opt)

    -- save to cache
    cacheinfo.xcode = xcode or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return xcode
end
