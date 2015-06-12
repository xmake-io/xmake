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
-- @file        android.lua
--

-- define module: android
local android = android or {}

-- load modules
local config        = require("base/config")

-- init host
android._HOST      = xmake._HOST

-- init architectures
android._ARCHS     = {"armv5te", "armv6", "armv7-a"}

-- make configure
function android.make(configs)

    -- init the file formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"lib", ".so"}
 
    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = "make"
    configs.tools.ccache    = config.get("__ccache")
    configs.tools.cc        = config.get("cc") 
    configs.tools.cxx       = config.get("cxx") 
    configs.tools.as        = config.get("as") 
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar")
    configs.tools.sh        = config.get("sh") 

    -- init flags
    configs.cxflags     = { "-march=" .. config.get("arch") }
    configs.asflags     = { "-march=" .. config.get("arch") }
    configs.ldflags     = { "-march=" .. config.get("arch"), "-llog" }
    configs.shflags     = { "-march=" .. config.get("arch"), "-llog" }

    -- add flags for the sdk directory of ndk
    local ndk_sdkdir = config.get("__ndk_sdkdir")
    if ndk_sdkdir then
        ndk_sdkdir = path.translate(ndk_sdkdir) 
        table.insert(configs.cxflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
        table.insert(configs.asflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
        table.insert(configs.ldflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
        table.insert(configs.shflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
    end

end

-- get the option menu for action: xmake config or global
function android.menu(action)

    -- init config option menu
    android._MENU_CONFIG = android._MENU_CONFIG or
            {   {}
            ,   {nil, "ndk",        "kv", nil,          "The NDK Directory"             }
            ,   {nil, "ndk_sdkver", "kv", "auto",       "The SDK Version for NDK"       }
            ,   }

    -- init global option menu
    android._MENU_GLOBAL = android._MENU_GLOBAL or
            {   {}
            ,   {nil, "ndk",        "kv", nil,          "The NDK Directory"             }
            ,   {nil, "ndk_sdkver", "kv", "auto",       "The SDK Version for NDK"       }
            ,   }

    -- get the option menu
    if action == "config" then
        return android._MENU_CONFIG
    elseif action == "global" then
        return android._MENU_GLOBAL
    end
end

-- return module: android
return android
