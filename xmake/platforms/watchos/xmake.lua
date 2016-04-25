--!The Automatic Cross-platform Build Tool
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
-- @file        xmake.lua
--

-- define platform
platform("watchos")

    -- set os
    set_platform_os("ios")

    -- set hosts
    set_platform_hosts("macosx")

    -- set archs
    set_platform_archs("armv7k")

    -- set checker
    set_platform_checker("checker")

    -- on load
    on_platform_load(function ()

        -- imports
        import("core.project.config")
        
        -- init the file formats
        _g.formats          = {}
        _g.formats.static   = {"lib", ".a"}
        _g.formats.object   = {"",    ".o"}
        _g.formats.shared   = {"lib", ".dylib"}

        -- init the tools
        _g.tools            = {}
        _g.tools.make       = config.get("make")
        _g.tools.ccache     = config.get("__ccache")
        _g.tools.cc         = config.get("cc")
        _g.tools.cxx        = config.get("cxx")
        _g.tools.mm         = config.get("mm") 
        _g.tools.mxx        = config.get("mxx") 
        _g.tools.ld         = config.get("ld") 
        _g.tools.as         = config.get("as") 
        _g.tools.ar         = config.get("ar") 
        _g.tools.sh         = config.get("sh") 
        _g.tools.ex         = config.get("ar") 
        _g.tools.sc         = config.get("sc") 
        _g.tools.lipo       = config.get("lipo") 

        -- init flags for architecture
        local arch          = config.get("arch")
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

    end)

    -- set menu
    set_platform_menu({
                        config = 
                        {   
                            {}   
                        ,   {nil, "mm",             "kv", nil,          "the objc compiler"                 }
                        ,   {nil, "mxx",            "kv", nil,          "the objc++ compiler"               }
                        ,   {nil, "mflags",         "kv", nil,          "the objc compiler flags"           }
                        ,   {nil, "mxflags",        "kv", nil,          "the objc/c++ compiler flags"       }
                        ,   {nil, "mxxflags",       "kv", nil,          "the objc++ compiler flags"         }
                        ,   {}
                        ,   {nil, "xcode_dir",      "kv", "auto",       "the xcode application directory"   }
                        ,   {nil, "xcode_sdkver",   "kv", "auto",       "the sdk version for xcode"         }
                        ,   {nil, "target_minver",  "kv", "auto",       "the target minimal version"        }
                        ,   {}
                        ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"     }
                        ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"        }
                        ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"     }
                        }

                    ,   global = 
                        {   
                            {}
                        ,   {nil, "xcode_dir",      "kv", "auto",       "the xcode application directory"   }
                        ,   {}
                        ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"     }
                        ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"        }
                        ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"     }
                        }
                    })






