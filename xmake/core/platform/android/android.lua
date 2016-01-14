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
android._HOST       = xmake._HOST

-- init os
android._OS         = "android"

-- init architectures
android._ARCHS      = {"armv5te", "armv6", "armv7-a", "armv8-a", "arm64-v8a"}

-- make configure
function android.make(configs)

    -- init the file formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"lib", ".so"}
 
    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = config.get("make")
    configs.tools.ccache    = config.get("__ccache")
    configs.tools.cc        = config.get("cc") 
    configs.tools.cxx       = config.get("cxx") 
    configs.tools.as        = config.get("as") 
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar")
    configs.tools.sh        = config.get("sh") 
    configs.tools.ex        = config.get("ar") 
    configs.tools.sc        = config.get("sc") 

    -- init flags
    local arch = config.get("arch")
    if arch:startswith("arm64") then
        configs.cxflags     = {}
        configs.asflags     = {}
        configs.ldflags     = {"-llog"}
        configs.shflags     = {"-llog"}
    else
        configs.cxflags     = { "-march=" .. arch, "-mthumb"}
        configs.asflags     = { "-march=" .. arch, "-mthumb"}
        configs.ldflags     = { "-march=" .. arch, "-llog", "-mthumb"}
        configs.shflags     = { "-march=" .. arch, "-llog", "-mthumb"}
    end

    -- add flags for the sdk directory of ndk
    local ndk = config.get("ndk")
    local ndk_sdkver = config.get("ndk_sdkver")
    if ndk and ndk_sdkver then
        local ndk_sdkdir = path.translate(string.format("%s/platforms/android-%d", ndk, ndk_sdkver)) 
        if arch:startswith("arm64") then
            table.insert(configs.cxflags, string.format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            table.insert(configs.asflags, string.format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            table.insert(configs.ldflags, string.format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            table.insert(configs.shflags, string.format("--sysroot=%s/arch-arm64", ndk_sdkdir))
        else
            table.insert(configs.cxflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
            table.insert(configs.asflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
            table.insert(configs.ldflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
            table.insert(configs.shflags, string.format("--sysroot=%s/arch-arm", ndk_sdkdir))
        end
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
