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
-- @file        load_macosx.lua
--

-- imports
import("core.project.config")

-- main entry
function main(toolchain)

    -- init flags for architecture
    local arch          = toolchain:arch()
    local target_minver = toolchain:config("target_minver")
    local xcode_sysroot = toolchain:config("xcode_sysroot")

    -- init target flags
    local appledev = toolchain:config("appledev")
    if target_minver then
        local target = ("%s-apple-macos%s"):format(arch, target_minver)
        if appledev == "catalyst" then
            target = ("%s-apple-ios%s-macabi"):format(arch, target_minver)
        end
        toolchain:add("cxflags", "-target", target)
        toolchain:add("mxflags", "-target", target)
        toolchain:add("asflags", "-target", target)
        toolchain:add("ldflags", "-target", target)
        toolchain:add("shflags", "-target", target)
        toolchain:add("scflags", "-target", target)
        toolchain:add("scldflags", "-target", target)
        toolchain:add("scshflags", "-target", target)
    end

    -- add sysroot flags
    if xcode_sysroot then
        toolchain:add("cxflags", "-isysroot", xcode_sysroot)
        toolchain:add("asflags", "-isysroot", xcode_sysroot)
        toolchain:add("ldflags", "-isysroot", xcode_sysroot)
        toolchain:add("shflags", "-isysroot", xcode_sysroot)
        toolchain:add("mxflags", "-isysroot", xcode_sysroot)
        toolchain:add("scflags", "-sdk " .. xcode_sysroot)
        toolchain:add("scshflags", "-sdk " .. xcode_sysroot)
        toolchain:add("scldflags", "-sdk " .. xcode_sysroot)
        if appledev == "catalyst" then
            toolchain:add("cxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
            toolchain:add("asflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
            toolchain:add("mxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
            toolchain:add("ldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
            toolchain:add("shflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
            toolchain:add("scldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
            toolchain:add("scshflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
            toolchain:add("cxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("asflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("ldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("shflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("mxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("scflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("scshflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
            toolchain:add("scldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        end
    end

    -- init flags for c/c++
    toolchain:add("ldflags", "-stdlib=libc++")
    toolchain:add("shflags", "-stdlib=libc++")
    toolchain:add("syslinks", "z")

    -- init flags for objc/c++ (with ldflags and shflags)
    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add("mxflags", "-fobjc-arc")
end
