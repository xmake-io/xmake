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
-- @file        load.lua
--

-- imports
import("core.project.config")

-- main entry
function main(toolchain)

    -- init flags for architecture
    local arch          = config.get("arch") or os.arch()
    local target_minver = config.get("target_minver")

    -- init flags for the xcode sdk directory
    local xcode_dir     = config.get("xcode")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = nil
    if xcode_dir and xcode_sdkver then
        xcode_sdkdir = xcode_dir .. "/Contents/Developer/toolchains/MacOSX.toolchain/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
    end

    -- init flags for c/c++
    toolchain:add("cxflags", "-arch " .. arch)
    toolchain:add("ldflags", "-arch " .. arch)
    if target_minver then
        toolchain:add("cxflags", "-mmacosx-version-min=" .. target_minver)
        toolchain:add("mxflags", "-mmacosx-version-min=" .. target_minver)
        toolchain:add("ldflags", "-mmacosx-version-min=" .. target_minver)
    end
    if xcode_sdkdir then
        toolchain:add("cxflags", "-isysroot " .. xcode_sdkdir)
        toolchain:add("ldflags", "-isysroot " .. xcode_sdkdir)
    else
        toolchain:add("cxflags", "-I/usr/local/include")
        toolchain:add("cxflags", "-I/usr/include")
        toolchain:add("ldflags", "-L/usr/local/lib")
        toolchain:add("ldflags", "-L/usr/lib")
    end
    toolchain:add("ldflags", "-stdlib=libc++")
    toolchain:add("ldflags", "-lz")
    toolchain:add("shflags", toolchain:get("ldflags"))

    -- init flags for objc/c++ (with ldflags and shflags)
    toolchain:add("mxflags", "-arch " .. arch)
    if xcode_sdkdir then
        toolchain:add("mxflags", "-isysroot " .. xcode_sdkdir)
    end

    -- init flags for asm 
--    toolchain:add("yasm.asflags", arch == "x86_64" and "macho64" or "macho32")
--    toolchain:set("fasm.asflags", "")
    toolchain:add("asflags", "-arch " .. arch)
    if xcode_sdkdir then
        toolchain:add("asflags", "-isysroot " .. xcode_sdkdir)
    end

    -- init flags for swift
    if target_minver and xcode_sdkdir then
        toolchain:add("scflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
        toolchain:add("scshflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
        toolchain:add("scldflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
    end

    --[[
    -- init flags for golang
    toolchain:set("gcldflags", "")

    -- init flags for dlang
    local dc_archs = { i386 = "-m32", x86_64 = "-m64" }
    toolchain:add("dcflags", dc_archs[arch] or "")
    toolchain:add("dcshflags", dc_archs[arch] or "")
    toolchain:add("dcldflags", dc_archs[arch] or "" )

    -- init flags for rust
    toolchain:set("rcshflags", "")
    toolchain:set("rcldflags", "")]]
end
