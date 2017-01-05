--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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

    -- init flags for architecture
    local arch          = config.get("arch")
    local target_minver = config.get("target_minver")
    _g.cxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0" }
    _g.mxflags = { "-arch " .. arch, "-fpascal-strings", "-fmessage-length=0" }
    _g.asflags = { "-arch " .. arch }
    _g.ldflags = { "-arch " .. arch, "-mmacosx-version-min=" .. target_minver, "-stdlib=libc++", "-lz" }
    _g.shflags = { "-arch " .. arch, "-mmacosx-version-min=" .. target_minver, "-stdlib=libc++", "-lz" }
    _g.scflags = { format("-target %s-apple-macosx%s", arch, target_minver) }

    -- init flags for the xcode sdk directory
    local xcode_dir     = config.get("xcode_dir")
    local xcode_sdkver  = config.get("xcode_sdkver")
    local xcode_sdkdir  = xcode_dir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
    insert(_g.cxflags, "-isysroot " .. xcode_sdkdir)
    insert(_g.asflags, "-isysroot " .. xcode_sdkdir)
    insert(_g.mxflags, "-isysroot " .. xcode_sdkdir)
    insert(_g.ldflags, "-isysroot " .. xcode_sdkdir)
    insert(_g.shflags, "-isysroot " .. xcode_sdkdir)
    insert(_g.scflags, "-sdk " .. xcode_sdkdir)

    -- init includedirs
    --
    -- @note 
    -- cannot use _g.includedirs because the swift/objc compiler will compile code failed
    insert(_g.cxflags, "-I/usr/include")
    insert(_g.cxflags, "-I/usr/local/include")

    -- init linkdirs
    _g.linkdirs    = {"/usr/lib", "/usr/local/lib"}

    -- save swift link directory for tools
    config.set("__swift_linkdirs", xcode_dir .. "/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx")

    -- ok
    return _g
end


