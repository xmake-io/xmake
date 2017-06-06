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

    -- init architecture
    local arch = config.get("arch")
    local simulator = arch == "i386"

    -- init platform name
    local platname = ifelse(simulator, "WatchSimulator", "WatchOS")

    -- init target minimal version
    local target_minver = config.get("target_minver")
    local target_minver_flags = ifelse(simulator, "-mwatchos-simulator-version-min=", "-mwatchos-version-min=") .. target_minver

    -- init the xcode sdk directory
    local xcode_dir     = config.get("xcode_dir")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = format("%s/Contents/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk", xcode_dir, platname, platname, xcode_sdkver)

    -- init flags for c/c++
    _g.cxflags = { "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir }
    _g.ldflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot " .. xcode_sdkdir }
    _g.shflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", target_minver_flags, "-isysroot " .. xcode_sdkdir }

    -- init flags for objc/c++
    _g.mxflags = { "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir }

    -- init flags for asm
    _g.asflags = { "-arch " .. arch, target_minver_flags, "-isysroot " .. xcode_sdkdir }

    -- init flags for swift (with _g.ldflags and _g.shflags)
    _g.scflags = { format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }
    _g["sc-shflags"] = { format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir } 
    _g["sc-ldflags"] = { format("-target %s-apple-ios%s", arch, target_minver) , "-sdk " .. xcode_sdkdir }

    -- ok
    return _g
end


