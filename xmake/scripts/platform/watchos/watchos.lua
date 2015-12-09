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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        watchos.lua
--

-- define module: watchos
local watchos = watchos or {}

-- load modules
local config        = require("base/config")

-- init host
watchos._HOST      = "macosx"

-- init os
watchos._OS        = "ios"

-- init architectures
watchos._ARCHS     = {"armv7", "armv7s", "arm64"}

-- make configure
function watchos.make(configs)

    -- init the file formats
    configs.formats         = {}
    configs.formats.static  = {"lib", ".a"}
    configs.formats.object  = {"",    ".o"}
    configs.formats.shared  = {"lib", ".dylib"}

    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = config.get("make")
    configs.tools.ccache    = config.get("__ccache")
    configs.tools.cc        = config.get("cc")
    configs.tools.cxx       = config.get("cxx")
    configs.tools.mm        = config.get("mm") 
    configs.tools.mxx       = config.get("mxx") 
    configs.tools.as        = config.get("as")
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar") 
    configs.tools.sh        = config.get("sh") 
    configs.tools.ex        = config.get("ar") 
    configs.tools.sc        = config.get("sc") 
    configs.tools.lipo      = config.get("lipo") 

    -- init target minimal version
    local target_minver = config.get("target_minver")
    assert(target_minver)

    -- init flags for architecture
    local archflags = nil
    local arch = config.get("arch")
    if arch then archflags = "-arch " .. arch end
    configs.cxflags     = { archflags, "-mwatchos-version-min=" .. target_minver }
    configs.mxflags     = { archflags, "-mwatchos-version-min=" .. target_minver }
    configs.asflags     = { archflags, "-mwatchos-version-min=" .. target_minver }
    configs.ldflags     = { archflags, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-version-min=" .. target_minver }
    configs.shflags     = { archflags, "-ObjC", "-lstdc++", "-fobjc-link-runtime", "-mwatchos-version-min=" .. target_minver }
    if arch then
        configs.scflags = { string.format("-target %s-apple-ios%s", arch, target_minver) }
    end
 
    -- init flags for the xcode sdk directory
    local xcode_dir     = config.get("xcode_dir")
    local xcode_sdkver  = config.get("xcode_sdkver")
    if xcode_dir and xcode_sdkver then

        -- init flags
        local xcode_sdkdir = xcode_dir .. "/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS" .. xcode_sdkver .. ".sdk"
        table.insert(configs.cxflags, "-isysroot " .. xcode_sdkdir)
        table.insert(configs.asflags, "-isysroot " .. xcode_sdkdir)
        table.insert(configs.mxflags, "-isysroot " .. xcode_sdkdir)
        table.insert(configs.ldflags, "-isysroot " .. xcode_sdkdir)
        table.insert(configs.shflags, "-isysroot " .. xcode_sdkdir)
        table.insert(configs.scflags, "-sdk " .. xcode_sdkdir)
 
        -- save swift link directory
        config.set("__swift_linkdirs", xcode_dir .. "/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/watchos")
    end

end

-- get the option menu for action: xmake config or global
function watchos.menu(action)

    -- init config option menu
    watchos._MENU_CONFIG = watchos._MENU_CONFIG or
            {   {}   
            ,   {nil, "mm",             "kv", nil,          "The Objc Compiler"                     }
            ,   {nil, "mxx",            "kv", nil,          "The Objc++ Compiler"                   }
            ,   {nil, "mflags",         "kv", nil,          "The Objc Compiler Flags"               }
            ,   {nil, "mxflags",        "kv", nil,          "The Objc/c++ Compiler Flags"           }
            ,   {nil, "mxxflags",       "kv", nil,          "The Objc++ Compiler Flags"             }
            ,   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"       }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK Version for Xcode"             }
            ,   {nil, "target_minver",  "kv", "auto",       "The Target Minimal Version"            }
            ,   {}
            ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"         }
            ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"            }
            ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"         }
            ,   }

    -- init global option menu
    watchos._MENU_GLOBAL = watchos._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"       }
            ,   {}
            ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"         }
            ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"            }
            ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"         }
            ,   }

    -- get the option menu
    if action == "config" then
        return watchos._MENU_CONFIG
    elseif action == "global" then
        return watchos._MENU_GLOBAL
    end
end


-- return module: watchos
return watchos
