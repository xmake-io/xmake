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
-- @file        _iphoneos.lua
--

-- define module: _iphoneos
local _iphoneos = _iphoneos or {}

-- load modules
local config        = require("base/config")

-- init host
_iphoneos._HOST      = "macosx"

-- init architectures
_iphoneos._ARCHS     = {"armv7", "armv7s", "arm64"}

-- init prober
_iphoneos._PROBER    = require("platform/iphoneos/_prober")

-- make configure
function _iphoneos.make(configs)

    -- init the file name format
    configs.format = {}
    configs.format.static = {"lib", ".a"}
    configs.format.object = {"",    ".o"}
    configs.format.shared = {"lib", ".dylib"}
 
    -- init the compiler
    configs.compiler = {}
    configs.compiler.cc  = config.get("cc") or "xcrun -sdk iphoneos clang"
    configs.compiler.cxx = config.get("cxx") or "xcrun -sdk iphoneos clang++"
    configs.compiler.mm  = config.get("mm") or configs.compiler.cc
    configs.compiler.mxx = config.get("mxx") or configs.compiler.cxx

    -- init the linker
    configs.linker = {}
    configs.linker.binary  = config.get("ld") or "xcrun -sdk iphoneos clang++"
    configs.linker.static  = config.get("ar") or "xcrun -sdk iphoneos ar"
    configs.linker.shared  = config.get("sh") or "xcrun -sdk iphoneos clang++"

    -- init xcode sdk directory
    configs.xcode_sdkdir = config.get("xcode_dir") .. "/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" .. config.get("xcode_sdkver") .. ".sdk"

end

-- get the option menu for action: xmake config or global
function _iphoneos.menu(action)

    -- init config option menu
    _iphoneos._MENU_CONFIG = _iphoneos._MENU_CONFIG or
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
    _iphoneos._MENU_GLOBAL = _iphoneos._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"       }
            ,   {}
            ,   {nil, "mobileprovision","kv", "auto",       "The Provisioning Profile File"         }
            ,   {nil, "codesign",       "kv", "auto",       "The Code Signing Indentity"            }
            ,   {nil, "entitlements",   "kv", "auto",       "The Code Signing Entitlements"         }
            ,   }

    -- get the option menu
    if action == "config" then
        return _iphoneos._MENU_CONFIG
    elseif action == "global" then
        return _iphoneos._MENU_GLOBAL
    end
end


-- return module: _iphoneos
return _iphoneos
