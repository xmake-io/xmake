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
-- imports
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- main entry
function main(toolchain)

    -- init target triple flags
    local targetflag = {"-target", toolchain_utils.get_xcode_target_triple(toolchain)}

    -- init flags for c/c++
    local xcode_sysroot = toolchain:config("xcode_sysroot")
    toolchain:add("cxflags", targetflag, "-isysroot", xcode_sysroot)
    toolchain:add("ldflags", targetflag, "-isysroot", xcode_sysroot, "-ObjC", "-fobjc-link-runtime")
    toolchain:add("shflags", targetflag, "-isysroot", xcode_sysroot, "-ObjC", "-fobjc-link-runtime")

    -- init flags for objc/c++
    toolchain:add("mxflags", targetflag, "-isysroot", xcode_sysroot)

    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add("mxflags", "-fobjc-arc")

    -- init flags for asm
    toolchain:add("asflags", targetflag, "-isysroot", xcode_sysroot)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add("scflags", {"-sdk", xcode_sysroot}, targetflag)
    toolchain:add("scshflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-library")
    toolchain:add("scarflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-library", "-static")
    toolchain:add("scldflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-executable")
end
