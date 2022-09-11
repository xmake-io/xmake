--!A cross-toolchain build utility based on Lua
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
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_xcode")

-- main entry
function main(toolchain)

    -- get apple device
    local simulator
    local appledev = toolchain:config("appledev") or config.get("appledev")
    if appledev and appledev == "simulator" then
        simulator = true
        appledev = "simulator"
    elseif not toolchain:is_plat("macosx") and toolchain:is_arch("i386", "x86_64") then
        simulator = true
        appledev = "simulator"
    end

    -- find xcode
    local xcode_sdkver = toolchain:config("xcode_sdkver") or config.get("xcode_sdkver")
    local xcode = find_xcode(config.get("xcode"), {force = true, verbose = true,
                                                   find_codesign = toolchain:is_global(),
                                                   sdkver = xcode_sdkver,
                                                   appledev = appledev,
                                                   plat = toolchain:plat(),
                                                   arch = toolchain:arch()})
    if not xcode then
        cprint("checking for Xcode directory ... ${color.nothing}${text.nothing}")
        return false
    end

    -- xcode found
    xcode_sdkver = xcode.sdkver
    if toolchain:is_global() then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
        config.set("xcode_mobile_provision", xcode.mobile_provision, {force = true, readonly = true})
        config.set("xcode_codesign_identity", xcode.codesign_identity, {force = true, readonly = true})
        cprint("checking for Xcode directory ... ${color.success}%s", xcode.sdkdir)
        if xcode.codesign_identity then
            cprint("checking for Codesign Identity of Xcode ... ${color.success}%s", xcode.codesign_identity)
        else
            cprint("checking for Codesign Identity of Xcode ... ${color.nothing}${text.nothing}")
        end
        if toolchain:is_plat("iphoneos") then
            if xcode.mobile_provision then
                cprint("checking for Mobile Provision of Xcode ... ${color.success}%s", xcode.mobile_provision)
            else
                cprint("checking for Mobile Provision of Xcode ... ${color.nothing}${text.nothing}")
            end
        end
    end

    -- save xcode sysroot directory
    local xcode_sysroot
    if xcode.sdkdir and xcode_sdkver then
        if toolchain:is_plat("macosx") then
            xcode_sysroot = xcode.sdkdir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
        elseif toolchain:is_plat("iphoneos") then
            local platname = simulator and "iPhoneSimulator" or "iPhoneOS"
            xcode_sysroot  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode.sdkdir, platname, platname, xcode_sdkver)
        elseif toolchain:is_plat("watchos") then
            local platname = simulator and "WatchSimulator" or "WatchOS"
            xcode_sysroot  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode.sdkdir, platname, platname, xcode_sdkver)
        elseif toolchain:is_plat("appletvos") then
            local platname = simulator and "AppleTVSimulator" or "AppleTVOS"
            xcode_sysroot  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode.sdkdir, platname, platname, xcode_sdkver)
        end
    end
    if xcode_sysroot then
        toolchain:config_set("xcode_sysroot", xcode_sysroot)
    end

    -- save target minver
    --
    -- @note we need to differentiate the version for the system,
    -- because the xcode toolchain of iphoneos/macosx may need to be used at the same time.
    --
    -- e.g.
    --
    -- target("test")
    --     set_toolchains("xcode", {plat = os.host(), arch = os.arch()})
    --
    local target_minver = toolchain:config("target_minver") or config.get("target_minver")
    if xcode_sdkver and not target_minver then
        target_minver = xcode.target_minver
    end
    toolchain:config_set("xcode", xcode.sdkdir)
    toolchain:config_set("xcode_sdkver", xcode_sdkver)
    toolchain:config_set("target_minver", target_minver)
    toolchain:config_set("appledev", appledev)
    toolchain:configs_save()
    if xcode_sdkver then
        cprint("checking for SDK version of Xcode for %s (%s) ... ${color.success}%s", toolchain:plat(), toolchain:arch(), xcode_sdkver)
    end
    if target_minver then
        cprint("checking for Minimal target version of Xcode for %s (%s) ... ${color.success}%s", toolchain:plat(), toolchain:arch(), target_minver)
    end
    return true
end
