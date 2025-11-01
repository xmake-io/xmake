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
-- @file        load_macosx.lua
--

function main(toolchain)
    -- init architecture
    local arch = toolchain:arch()
    local xcode_sdkver = toolchain:config('xcode_sdkver')
    local xcode_sysroot = toolchain:config('xcode_sysroot')

    -- is simulator?
    local appledev = toolchain:config('appledev')
    local simulator = appledev == 'simulator'
    assert(not simulator)
    local catalyst = appledev == 'catalyst'

    -- init target minimal version
    local target_minver = toolchain:config('target_minver')
    local targetflag = format("%s-apple-macos", arch)
    if target_minver then
        targetflag = targetflag .. target_minver
    end
    if catalyst then
        targetflag = targetflag .. "-macabi"
    end
    targetflag = {"-target", targetflag}

    -- init flags for c/c++
    toolchain:add('cxflags', {'-arch', arch}, targetflag, {'-isysroot', xcode_sysroot})
    toolchain:add('ldflags', {'-arch', arch}, targetflag, {'-isysroot', xcode_sysroot}, '-lz')
    toolchain:add('shflags', {'-arch', arch}, targetflag, {'-isysroot', xcode_sysroot}, '-lz')

    -- init flags for objc/c++
    toolchain:add('mxflags', {'-arch', arch}, targetflag, {'-isysroot', xcode_sysroot})

    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add('mxflags', '-fobjc-arc')

    -- init flags for asm
    toolchain:add('asflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add('scflags', {'-sdk', xcode_sysroot}, targetflag)
    toolchain:add('scshflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-library")
    toolchain:add('scarflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-library", "-static")
    toolchain:add('scldflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-executable")

    if xcode_sysroot and catalyst then
        toolchain:add("cxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
        toolchain:add("mxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})

        toolchain:add("asflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
        toolchain:add("ldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
        toolchain:add("shflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})

        toolchain:add("scflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
        toolchain:add("scldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
        toolchain:add("scshflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
        toolchain:add("scarflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})

        toolchain:add("cxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("mxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})

        toolchain:add("asflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("ldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("shflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})

        toolchain:add("scflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("scshflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("scarflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
        toolchain:add("scldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    end
end
