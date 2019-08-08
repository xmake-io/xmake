--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main(platform)

    -- init flags for architecture
    local arch          = config.get("arch") or os.arch()
    local target_minver = config.get("target_minver")

    -- init flags for the xcode sdk directory
    local xcode_dir     = config.get("xcode")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = nil
    if xcode_dir and xcode_sdkver then
        xcode_sdkdir = xcode_dir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
    end

    -- init flags for c/c++
    platform:add("cxflags", "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0")
    platform:add("ldflags", "-arch " .. arch)
    if target_minver then
        platform:add("cxflags", "-mmacosx-version-min=" .. target_minver)
        platform:add("mxflags", "-mmacosx-version-min=" .. target_minver)
        platform:add("ldflags", "-mmacosx-version-min=" .. target_minver)
    end
    if xcode_sdkdir then
        platform:add("cxflags", "-isysroot " .. xcode_sdkdir)
        platform:add("ldflags", "-isysroot " .. xcode_sdkdir)
    else
        platform:add("cxflags", "-I/usr/local/include")
        platform:add("cxflags", "-I/usr/include")
        platform:add("ldflags", "-L/usr/local/lib")
        platform:add("ldflags", "-L/usr/lib")
    end
    platform:add("ldflags", "-stdlib=libc++")
    platform:add("ldflags", "-lz")
    platform:add("shflags", platform:get("ldflags"))

    -- init flags for objc/c++ (with ldflags and shflags)
    platform:add("mxflags", "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0")
    if xcode_sdkdir then
        platform:add("mxflags", "-isysroot " .. xcode_sdkdir)
    end

    -- init flags for asm 
    platform:add("yasm.asflags", arch == "x86_64" and "macho64" or "macho32")
    platform:set("fasm.asflags", "")
    platform:add("asflags", "-arch " .. arch)
    if xcode_sdkdir then
        platform:add("asflags", "-isysroot " .. xcode_sdkdir)
    end

    -- init flags for swift
    if target_minver and xcode_sdkdir then
        platform:add("scflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
        platform:add("sc-shflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
        platform:add("sc-ldflags", format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir)
    end

    -- init flags for golang
    platform:set("gc-ldflags", "")

    -- init flags for dlang
    local dc_archs = { i386 = "-m32", x86_64 = "-m64" }
    platform:add("dcflags", dc_archs[arch] or "")
    platform:add("dc-shflags", dc_archs[arch] or "")
    platform:add("dc-ldflags", dc_archs[arch] or "" )

    -- init flags for rust
    platform:set("rc-shflags", "")
    platform:set("rc-ldflags", "")
end

