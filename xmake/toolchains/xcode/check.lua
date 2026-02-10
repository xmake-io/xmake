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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_xcode")
import("private.utils.toolchain", {alias = "toolchain_utils"})
import("private.utils.executable_path")
import("private.tools.codesign")

-- print Xcode SDK summary (single line) and optional codesign infos
function _show_checkinfo(toolchain, xcode, xcode_sdkver, target_minver)
    if xcode and xcode.sdkdir then
        local extras = {}
        if xcode_sdkver then
            table.insert(extras, "sdk: " .. xcode_sdkver)
        end
        local target_triple = toolchain_utils.get_xcode_target_triple(toolchain)
        if target_triple then
            table.insert(extras, target_triple)
        end
        local extra = ""
        if #extras > 0 then
            extra = " (" .. table.concat(extras, ", ") .. ")"
        end
        cprint("checking for Xcode SDK ... ${color.success}%s%s", xcode.sdkdir, extra)
    else
        cprint("checking for Xcode SDK ... ${color.nothing}${text.nothing}")
    end

    if option.get("verbose") then
        local codesign_identity = codesign.xcode_codesign_identity()
        if codesign_identity then
            cprint("checking for Codesign Identity of Xcode ... ${color.success}%s", codesign_identity)
        else
            cprint("checking for Codesign Identity of Xcode ... ${color.nothing}${text.nothing}")
        end
        if toolchain:is_plat("iphoneos") then
            local mobile_provision = codesign.xcode_mobile_provision()
            if mobile_provision then
                cprint("checking for Mobile Provision of Xcode ... ${color.success}%s", mobile_provision)
            else
                cprint("checking for Mobile Provision of Xcode ... ${color.nothing}${text.nothing}")
            end
        end
    end
end

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
                                                   sdkver = xcode_sdkver,
                                                   appledev = appledev,
                                                   plat = toolchain:plat(),
                                                   arch = toolchain:arch()})
    if not xcode then
        cprint("checking for Xcode SDK ... ${color.nothing}${text.nothing}")
        return false
    end

    -- xcode found
    xcode_sdkver = xcode.sdkver
    if toolchain:is_global() then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
    end

    -- get xcode bin directory
    local cross
    if xcode.sdkdir and os.isdir(xcode.sdkdir) then
        local bindir = path.join(xcode.sdkdir, "Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin")
        toolchain:config_set("bindir", bindir)
    else
        if toolchain:is_plat("macosx") then
            cross = "xcrun -sdk macosx "
        elseif toolchain:is_plat("iphoneos") then
            cross = simulator and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "
        elseif toolchain:is_plat("watchos") then
            cross = simulator and "xcrun -sdk watchsimulator " or "xcrun -sdk watchos "
        elseif toolchain:is_plat("appletvos") then
            cross = simulator and "xcrun -sdk appletvsimulator " or "xcrun -sdk appletvos "
        elseif toolchain:is_plat("applexros") then
            cross = simulator and "xcrun -sdk xrsimulator " or "xcrun -sdk xros "
        else
            raise("unknown platform for xcode!")
        end
        local xc_clang = executable_path(cross .. "clang")
        if xc_clang then
            toolchain:config_set("bindir", path.directory(xc_clang))
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
        elseif toolchain:is_plat("applexros") then
            local platname = simulator and "XRSimulator" or "XROS"
            xcode_sysroot  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode.sdkdir, platname, platname, xcode_sdkver)
        end
    else
        -- maybe it is from CommandLineTools, e.g. /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
        -- @see https://github.com/xmake-io/xmake/issues/3686
        local sdkpath = try { function () return os.iorun(cross .. "--show-sdk-path") end }
        if sdkpath then
            xcode_sysroot = sdkpath:trim()
        end
    end
    if xcode_sysroot then
        toolchain:config_set("xcode_sysroot", xcode_sysroot)
    end
    toolchain:config_set("simulator", simulator)

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
    if toolchain:is_global() then
        _show_checkinfo(toolchain, xcode, xcode_sdkver, target_minver)
    end
    return true
end
