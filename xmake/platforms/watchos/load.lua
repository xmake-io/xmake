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

    -- init the file formats
    _g.formats          = {}
    _g.formats.static   = {"lib", ".a"}
    _g.formats.object   = {"",    ".o"}
    _g.formats.shared   = {"lib", ".dylib"}
    _g.formats.symbol   = {"",    ".sym"}

    -- watchos or watchsimulator?
    local arch = config.get("arch")
    if arch == "i386" then

        -- init flags for architecture
        local target_minver = config.get("target_minver")
        _g.cxflags = { "-arch " .. arch, "-mwatchos-simulator-version-min=" .. target_minver }
        _g.mxflags = { "-arch " .. arch, "-mwatchos-simulator-version-min=" .. target_minver }
        _g.asflags = { "-arch " .. arch, "-mwatchos-simulator-version-min=" .. target_minver }
        _g.ldflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-simulator-version-min=" .. target_minver }
        _g.shflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-simulator-version-min=" .. target_minver }
        _g.ldflags = { "-arch " .. arch, "-Xlinker -objc_abi_version", "-Xlinker 2 -stdlib=libc++", "-Xlinker -no_implicit_dylibs", "-fobjc-link-runtime", "-mwatchos-simulator-version-min=" .. target_minver }
        _g.shflags = { "-arch " .. arch, "-Xlinker -objc_abi_version", "-Xlinker 2 -stdlib=libc++", "-Xlinker -no_implicit_dylibs", "-fobjc-link-runtime", "-mwatchos-simulator-version-min=" .. target_minver }
        _g.scflags = { format("-target %s-apple-ios%s", arch, target_minver) }

        -- init flags for the xcode sdk directory
        local xcode_dir     = config.get("xcode_dir")
        local xcode_sdkver  = config.get("xcode_sdkver")
        local xcode_sdkdir  = xcode_dir .. "/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator" .. xcode_sdkver .. ".sdk"
        insert(_g.cxflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.asflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.mxflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.ldflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.shflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.scflags, "-sdk " .. xcode_sdkdir)

        -- save swift link directory for tools
        config.set("__swift_linkdirs", xcode_dir .. "/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/watchsimulator")
    else

        -- init flags for architecture
        local target_minver = config.get("target_minver")
        _g.cxflags = { "-arch " .. arch, "-mwatchos-version-min=" .. target_minver }
        _g.mxflags = { "-arch " .. arch, "-mwatchos-version-min=" .. target_minver }
        _g.asflags = { "-arch " .. arch, "-mwatchos-version-min=" .. target_minver }
        _g.ldflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-version-min=" .. target_minver }
        _g.shflags = { "-arch " .. arch, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-version-min=" .. target_minver }
        _g.scflags = { format("-target %s-apple-ios%s", arch, target_minver) }

        -- init flags for the xcode sdk directory
        local xcode_dir     = config.get("xcode_dir")
        local xcode_sdkver  = config.get("xcode_sdkver")
        local xcode_sdkdir  = xcode_dir .. "/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS" .. xcode_sdkver .. ".sdk"
        insert(_g.cxflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.asflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.mxflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.ldflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.shflags, "-isysroot " .. xcode_sdkdir)
        insert(_g.scflags, "-sdk " .. xcode_sdkdir)

        -- save swift link directory for tools
        config.set("__swift_linkdirs", xcode_dir .. "/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/watchos")
    end

    -- ok
    return _g
end


