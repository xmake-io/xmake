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
-- @file        load_platform.lua
--

function main(toolchain, plat)
    -- init architecture
    local arch = toolchain:arch()
    local xcode_sdkver = toolchain:config('xcode_sdkver')
    local xcode_sysroot = toolchain:config('xcode_sysroot')

    -- is simulator?
    local appledev = toolchain:config('appledev') 
    local simulator = appledev == 'simulator'

    -- init target minimal version
    local target_minver = toolchain:config('target_minver')
    if target_minver then
        if plat == "ios" and tonumber(target_minver) > 10 and (arch == 'armv7' or arch == 'armv7s' or arch == 'i386') then
            target_minver = '10' -- iOS 10 is the maximum deployment target for 32-bit targets
        end
    end
    local targetflag = format("%s-apple-%s%s%s", arch, plat, target_minver or "", simulator and "-simulator" or "")
    targetflag = {"-target", targetflag}

    -- init flags for c/c++
    toolchain:add('cxflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot)
    toolchain:add('ldflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot, '-ObjC', '-fobjc-link-runtime')
    toolchain:add('shflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot, '-ObjC', '-fobjc-link-runtime')

    -- init flags for objc/c++
    toolchain:add('mxflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot)

    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add('mxflags', '-fobjc-arc')

    -- init flags for asm
    toolchain:add('asflags', {'-arch', arch}, targetflag, '-isysroot', xcode_sysroot)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add('scflags', {'-sdk', xcode_sysroot}, targetflag)
    toolchain:add('scshflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-library")
    toolchain:add('scarflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-library", "-static")
    toolchain:add('scldflags', {'-sdk', xcode_sysroot}, targetflag, "-emit-executable")
end
