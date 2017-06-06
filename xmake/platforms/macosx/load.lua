--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
    local xcode_dir     = config.get("xcode_dir")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = xcode_dir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"

    -- init flags for c/c++
    _g.cxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0", "-isysroot " .. xcode_sdkdir, "-I/usr/local/include", "-I/usr/include" }
    _g.ldflags = { "-arch " .. arch, "-mmacosx-version-min=" .. target_minver, "-isysroot " .. xcode_sdkdir, "-L/usr/local/lib", "-L/usr/lib", "-stdlib=libc++", "-lz" }
    _g.shflags = { "-arch " .. arch, "-mmacosx-version-min=" .. target_minver, "-isysroot " .. xcode_sdkdir, "-L/usr/local/lib", "-L/usr/lib", "-stdlib=libc++", "-lz" }

    -- init flags for objc/c++ (with _g.ldflags and _g.shflags)
    _g.mxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0", "-isysroot " .. xcode_sdkdir }

    -- init flags for asm (with _g.ldflags and _g.shflags)
    _g.asflags = { "-arch " .. arch, "-isysroot " .. xcode_sdkdir }

    -- init flags for swift
    _g.scflags = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
    _g["sc-shflags"] = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
    _g["sc-ldflags"] = { format("-target %s-apple-macosx%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }

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

    -- ok
    return _g
end


