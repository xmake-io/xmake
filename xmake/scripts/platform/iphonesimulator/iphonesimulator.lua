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
-- @file        iphonesimulator.lua
--

-- define module: iphonesimulator
local iphonesimulator = iphonesimulator or {}

-- load modules
local config                = require("base/config")

-- init host
iphonesimulator._HOST       = "macosx"

-- init architectures
iphonesimulator._ARCHS      = {"i386"}

-- make configure
function iphonesimulator.make(configs)

    -- init the file formats
    configs.formats         = {}
    configs.formats.static  = {"lib", ".a"}
    configs.formats.object  = {"",    ".o"}
    configs.formats.shared  = {"lib", ".dylib"}
 
    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = "make"
    configs.tools.ccache    = config.get("__ccache")
    configs.tools.cc        = config.get("cc") or "xcrun -sdk iphonesimulator clang"
    configs.tools.cxx       = config.get("cxx") or "xcrun -sdk iphonesimulator clang++"
    configs.tools.mm        = config.get("mm") or configs.tools.cc
    configs.tools.mxx       = config.get("mxx") or configs.tools.cxx
    configs.tools.ld        = config.get("ld") or "xcrun -sdk iphonesimulator clang++"
    configs.tools.ar        = config.get("ar") or "xcrun -sdk iphonesimulator ar"
    configs.tools.sh        = config.get("sh") or "xcrun -sdk iphonesimulator clang++"

    -- init xcode sdk directory
    configs.xcode_sdkdir    = config.get("xcode_dir") .. "/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" .. config.get("xcode_sdkver") .. ".sdk"

    -- init flags
    configs.cxflags         = "-isysroot " .. configs.xcode_sdkdir
    configs.mxflags         = "-isysroot " .. configs.xcode_sdkdir
    configs.ldflags         = "-isysroot " .. configs.xcode_sdkdir
    configs.shflags         = "-isysroot " .. configs.xcode_sdkdir

end

-- get the option menu for action: xmake config or global
function iphonesimulator.menu(action)

    -- init config option menu
    iphonesimulator._MENU_CONFIG = iphonesimulator._MENU_CONFIG or
            {   {}   
            ,   {nil, "mm",             "kv", nil,          "The Objc Compiler"                     }
            ,   {nil, "mxx",            "kv", nil,          "The Objc++ Compiler"                   }
            ,   {nil, "mflags",         "kv", nil,          "The Objc Compiler Flags"               }
            ,   {nil, "mxflags",        "kv", nil,          "The Objc/c++ Compiler Flags"           }
            ,   {nil, "mxxflags",       "kv", nil,          "The Objc++ Compiler Flags"             }
            ,   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"       }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK Version for Xcode"             }
            ,   {}
            ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"         }
            ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"            }
            ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"         }
            ,   }

    -- init global option menu
    iphonesimulator._MENU_GLOBAL = iphonesimulator._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"       }
            ,   {}
            ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"         }
            ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"            }
            ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"         }
            ,   }

    -- get the option menu
    if action == "config" then
        return iphonesimulator._MENU_CONFIG
    elseif action == "global" then
        return iphonesimulator._MENU_GLOBAL
    end
end


-- return module: iphonesimulator
return iphonesimulator
