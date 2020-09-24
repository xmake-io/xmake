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
-- @file        find_xcode.lua
--

-- imports
import("lib.detect.cache")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("lib.detect.find_directory")
import("private.tools.codesign")

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

    -- find codesign identity
    local codesign_identity = config.get("xcode_codesign_identity")
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
    local mobile_provision
    if is_plat("iphoneos") then
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
    return {sdkdir = sdkdir, sdkver = sdkver, codesign_identity = codesign_identity, mobile_provision = mobile_provision}
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

    -- get xcode sdk version
    local xcode_sdkver = (plat == config.plat()) and config.get("xcode_sdkver")
    if not xcode_sdkver then
        xcode_sdkver = config.get("xcode_sdkver_" .. plat)
    end

    -- find xcode
    local xcode = _find_xcode(sdkdir or config.get("xcode") or global.get("xcode"), opt.sdkver or xcode_sdkver, plat, arch)
    if xcode and xcode.sdkdir then

        -- save to config
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
        config.set("xcode_sdkver_" .. plat, xcode.sdkver, {force = true, readonly = true})
        config.set("xcode_codesign_identity", xcode.codesign_identity, {force = true, readonly = true})
        config.set("xcode_mobile_provision", xcode.mobile_provision, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Xcode directory ... ${color.success}%s", xcode.sdkdir)
            cprint("checking for SDK version of Xcode ... ${color.success}%s", xcode.sdkver)
            if xcode.codesign_identity then
                cprint("checking for Codesign Identity of Xcode ... ${color.success}%s", xcode.codesign_identity)
            else
                cprint("checking for Codesign Identity of Xcode ... ${color.nothing}${text.nothing}")
            end
            if plat == "iphoneos" then
                if xcode.mobile_provision then
                    cprint("checking for Mobile Provision of Xcode ... ${color.success}%s", xcode.mobile_provision)
                else
                    cprint("checking for Mobile Provision of Xcode ... ${color.nothing}${text.nothing}")
                end
            end
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Xcode directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.xcode = xcode or false
    cache.save(key, cacheinfo)

    -- ok?
    return xcode
end
