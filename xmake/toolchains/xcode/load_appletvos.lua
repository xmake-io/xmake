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
-- @file        load_appletvos.lua
--

-- imports
import("core.project.config")

-- main entry
function main(toolchain)

    -- init architecture
    local arch = toolchain:arch()
    local xcode_sdkver  = toolchain:config("xcode_sdkver")
    local xcode_sysroot = toolchain:config("xcode_sysroot")

    -- is simulator?
    local simulator = toolchain:config("appledev") == "simulator"

    -- init target minimal version
    local target_minver = toolchain:config("target_minver")
    local target_minver_flags = (simulator and "-mappletv-simulator-version-min=" or "-mappletvos-version-min=") .. target_minver

    -- init flags for c/c++
    toolchain:add("cxflags", "-arch", arch, target_minver_flags, "-isysroot", xcode_sysroot)
    toolchain:add("ldflags", "-arch", arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot", xcode_sysroot)
    toolchain:add("shflags", "-arch", arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot", xcode_sysroot)

    -- init flags for objc/c++
    toolchain:add("mxflags", "-arch", arch, target_minver_flags, "-isysroot", xcode_sysroot)
    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add("mxflags", "-fobjc-arc")

    -- init flags for asm
    toolchain:add("asflags", "-arch", arch, target_minver_flags, "-isysroot", xcode_sysroot)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add("scflags", format("-target %s-apple-tvos%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
    toolchain:add("scshflags", format("-target %s-apple-tvos%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
    toolchain:add("scldflags", format("-target %s-apple-tvos%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
end

