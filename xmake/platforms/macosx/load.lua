--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main()

    -- init flags for architecture
    local arch          = config.get("arch")
    local target_minver = config.get("target_minver")

    -- init flags for the xcode sdk directory
    local xcode_dir     = config.get("xcode")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = nil
    if xcode_dir and xcode_sdkver then
        xcode_sdkdir = xcode_dir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
    end

    -- init flags for c/c++
    _g.cxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0" }
    _g.ldflags = { "-arch " .. arch }
    if target_minver then
        table.insert(_g.ldflags, "-mmacosx-version-min=" .. target_minver)
    end
    if xcode_sdkdir then
        table.insert(_g.cxflags, "-isysroot " .. xcode_sdkdir)
        table.insert(_g.ldflags, "-isysroot " .. xcode_sdkdir)
    else
        table.insert(_g.cxflags, "-I/usr/local/include")
        table.insert(_g.cxflags, "-I/usr/include")
        table.insert(_g.ldflags, "-L/usr/local/lib")
        table.insert(_g.ldflags, "-L/usr/lib")
    end
    table.insert(_g.ldflags, "-stdlib=libc++")
    table.insert(_g.ldflags, "-lz")
    _g.shflags = table.copy(_g.ldflags)

    -- init flags for objc/c++ (with _g.ldflags and _g.shflags)
    _g.mxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0" }
    if xcode_sdkdir then
        table.insert(_g.mxflags, "-isysroot " .. xcode_sdkdir)
    end

    -- init flags for asm 
    local as = config.get("as")
    if as == "yasm" then
        _g.asflags = { "-f", "macho64" }
    else
        _g.asflags = { "-arch " .. arch }
        if xcode_sdkdir then
            table.insert(_g.asflags, "-isysroot " .. xcode_sdkdir)
        end
    end

    -- init flags for swift
    if target_minver and xcode_sdkdir then
        _g.scflags = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
        _g["sc-shflags"] = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
        _g["sc-ldflags"] = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
    end

    -- init flags for golang
    _g["gc-ldflags"] = {}

    -- init flags for dlang
    local dc_archs = { i386 = "-m32", x86_64 = "-m64" }
    _g.dcflags       = { dc_archs[arch] or "" }
    _g["dc-shflags"] = { dc_archs[arch] or "" }
    _g["dc-ldflags"] = { dc_archs[arch] or "" }

    -- init flags for rust
    _g["rc-shflags"] = {}
    _g["rc-ldflags"] = {}

    -- init flags for cuda
    local cu_archs = { i386 = "-m32 -Xcompiler -arch -Xcompiler i386", x86_64 = "-m64 -Xcompiler -arch -Xcompiler x86_64" }
    _g.cuflags = {cu_archs[arch] or ""}
    _g["cu-shflags"] = {cu_archs[arch] or ""}
    _g["cu-ldflags"] = {cu_archs[arch] or ""}
    local cuda_dir = config.get("cuda")
    if cuda_dir then
        table.insert(_g.cuflags, "-I" .. os.args(path.join(cuda_dir, "include")))
        table.insert(_g["cu-ldflags"], "-L" .. os.args(path.join(cuda_dir, "lib")))
        table.insert(_g["cu-shflags"], "-L" .. os.args(path.join(cuda_dir, "lib")))
        table.insert(_g["cu-ldflags"], "-Xlinker -rpath -Xlinker " .. os.args(path.join(cuda_dir, "lib")))
    end

    -- ok
    return _g
end

