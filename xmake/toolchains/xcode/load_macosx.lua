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

    -- init flags for c/c++
    toolchain:add("cxflags", "-arch " .. arch)
    toolchain:add("ldflags", "-arch " .. arch)
    toolchain:add("shflags", "-arch " .. arch)
    if target_minver then
        toolchain:add("cxflags", "-mmacosx-version-min=" .. target_minver)
        toolchain:add("mxflags", "-mmacosx-version-min=" .. target_minver)
        toolchain:add("ldflags", "-mmacosx-version-min=" .. target_minver)
        toolchain:add("shflags", "-mmacosx-version-min=" .. target_minver)
    end
    if xcode_sysroot then
        toolchain:add("cxflags", "-isysroot " .. xcode_sysroot)
        toolchain:add("ldflags", "-isysroot " .. xcode_sysroot)
        toolchain:add("shflags", "-isysroot " .. xcode_sysroot)
    end
    toolchain:add("ldflags", "-stdlib=libc++")
    toolchain:add("shflags", "-stdlib=libc++")
    toolchain:add("syslinks", "z")

    -- init flags for objc/c++ (with ldflags and shflags)
    toolchain:add("mxflags", "-arch " .. arch)
    if xcode_sysroot then
        toolchain:add("mxflags", "-isysroot " .. xcode_sysroot)
    end

    -- init flags for asm
    toolchain:add("asflags", "-arch " .. arch)
    if xcode_sysroot then
        toolchain:add("asflags", "-isysroot " .. xcode_sysroot)
    end

    -- init flags for swift
    if target_minver and xcode_sysroot then
        toolchain:add("scflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
        toolchain:add("scshflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
        toolchain:add("scldflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sysroot)
    end
end
