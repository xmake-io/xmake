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
import("core.project.config")
import("detect.sdks.find_xcode")
import("detect.sdks.find_cross_toolchain")

-- find xcode on macos
function _find_xcode(toolchain)

    -- find xcode
    local xcode_sdkver = toolchain:config("xcode_sdkver") or config.get("xcode_sdkver")
    local xcode = find_xcode(config.get("xcode"), {force = true, verbose = true,
                                                   find_codesign = false,
                                                   sdkver = xcode_sdkver,
                                                   plat = toolchain:plat(),
                                                   arch = toolchain:arch()})
    if not xcode then
        cprint("checking for Xcode directory ... ${color.nothing}${text.nothing}")
        return
    end

    -- xcode found
    xcode_sdkver = xcode.sdkver
    if toolchain:global() then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
        cprint("checking for Xcode directory ... ${color.success}%s", xcode.sdkdir)
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
    local target_minver = toolchain:config("target_minver") and config.get("target_minver")
    if xcode_sdkver and not target_minver then
        target_minver = xcode_sdkver
        if toolchain:is_plat("macosx") then
            local macos_ver = macos.version()
            if macos_ver then
                target_minver = macos_ver:major() .. "." .. macos_ver:minor()
            end
        end
    end
    toolchain:config_set("xcode", xcode.sdkdir)
    toolchain:config_set("xcode_sdkver", xcode_sdkver)
    toolchain:config_set("target_minver", target_minver)
    toolchain:configs_save()
    cprint("checking for SDK version of Xcode for %s (%s) ... ${color.success}%s", toolchain:plat(), toolchain:arch(), xcode_sdkver)
    cprint("checking for Minimal target version of Xcode for %s (%s) ... ${color.success}%s", toolchain:plat(), toolchain:arch(), target_minver)
end

-- check the cross toolchain
function main(toolchain)

    -- get sdk directory
    local sdkdir = config.get("sdk")
    local bindir = config.get("bin")
    if not sdkdir and not bindir then
        if toolchain:is_plat("linux") and os.isfile("/usr/bin/llvm-ar") then
            sdkdir = "/usr"
        end
    end

    -- find cross toolchain
    local cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir})
    if cross_toolchain then
        config.set("cross", cross_toolchain.cross, {readonly = true, force = true})
        config.set("bin", cross_toolchain.bindir, {readonly = true, force = true})
    else
        raise("llvm toolchain not found!")
    end

    -- attempt to find xcode to pass `-isysroot` on macos
    if toolchain:is_plat("macosx") then
        _find_xcode(toolchain)
    end
    return cross_toolchain
end
