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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load_iphoneos.lua
--

-- imports
import("core.project.config")

-- main entry
function main(toolchain)

    -- init architecture
    local arch = toolchain:arch()
    local simulator = (arch == "i386" or arch == "x86_64")

    -- init platform name
    local platname = simulator and "iPhoneSimulator" or "iPhoneOS"

    -- init target minimal version
    local target_minver = config.get("target_minver_iphoneos")
    if target_minver and tonumber(target_minver) > 10 and (arch == "armv7" or arch == "armv7s" or arch == "i386") then
        target_minver = "10" -- iOS 10 is the maximum deployment target for 32-bit targets
    end
    local target_minver_flags = (simulator and "-mios-simulator-version-min=" or "-miphoneos-version-min=") .. target_minver

    -- init the xcode sdk directory
    local xcode_dir     = config.get("xcode")
    local xcode_sdkver  = config.get("xcode_sdkver_iphoneos")
    local xcode_sdkdir  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode_dir, platname, platname, xcode_sdkver)

    -- init flags for c/c++
    toolchain:add("cxflags", "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir)
    toolchain:add("ldflags", "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot " .. xcode_sdkdir)
    toolchain:add("shflags", "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot " .. xcode_sdkdir)

    -- init flags for objc/c++
    toolchain:add("mxflags", "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir)

    -- init flags for asm
    toolchain:add("asflags", "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add("scflags", format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
    toolchain:add("scshflags", format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
    toolchain:add("scldflags", format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
end

