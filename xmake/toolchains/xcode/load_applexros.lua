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
-- @file        load_applexros.lua
--

function main(toolchain)

    local arch = toolchain:arch()
    local xcode_sdkver  = toolchain:config("xcode_sdkver")
    local xcode_sysroot = toolchain:config("xcode_sysroot")
    local target_minver = toolchain:config("target_minver")

    -- init target flags
    if target_minver then
        local simulator = toolchain:config("appledev") == "simulator"
        local target = (simulator and "%s-apple-xrsimulator%s" or "%s-apple-xros%s"):format(arch, target_minver)
        toolchain:add("cxflags", "-target", target)
        toolchain:add("mxflags", "-target", target)
        toolchain:add("asflags", "-target", target)
        toolchain:add("ldflags", "-target", target)
        toolchain:add("shflags", "-target", target)
        toolchain:add("scflags", "-target", target)
        toolchain:add("scldflags", "-target", target)
        toolchain:add("scshflags", "-target", target)
    end

    -- init flags for c/c++
    toolchain:add("cxflags", "-isysroot", xcode_sysroot)
    toolchain:add("ldflags", "-fobjc-link-runtime", "-isysroot", xcode_sysroot)
    toolchain:add("shflags", "-fobjc-link-runtime", "-isysroot", xcode_sysroot)

    -- init flags for objc/c++
    toolchain:add("mxflags", "-isysroot", xcode_sysroot)
    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add("mxflags", "-fobjc-arc")

    -- init flags for asm
    toolchain:add("asflags", "-isysroot", xcode_sysroot)

    -- init flags for swift (with toolchain:add("ldflags and toolchain:add("shflags)
    toolchain:add("scflags", "-sdk " .. xcode_sysroot)
    toolchain:add("scshflags", "-sdk " .. xcode_sysroot)
    toolchain:add("scldflags", "-sdk " .. xcode_sysroot)
end

