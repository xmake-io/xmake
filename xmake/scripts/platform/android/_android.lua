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
-- @file        _android.lua
--

-- define module: _android
local _android = _android or {}

-- load modules
local config        = require("base/config")

-- init host
_android._HOST      = xmake._HOST

-- init architectures
_android._ARCHS     = {"armv5te", "armv6", "armv7-a"}

-- init prober
_android._PROBER    = require("platform/android/_prober")

-- make configure
function _android.make(configs)

    -- init the file name format
    configs.format = {}
    configs.format.static = {"lib", ".a"}
    configs.format.object = {"",    ".o"}
    configs.format.shared = {"",    ".so"}

end

-- get the option menu for action: xmake config or global
function _android.menu(action)

    -- init config option menu
    _android._MENU_CONFIG = _android._MENU_CONFIG or
            {   {}
            ,   {nil, "ndk",        "kv", nil,          "The NDK Directory"             }
            ,   {nil, "ndk_sdkver", "kv", "auto",       "The SDK Version for NDK"       }
            ,   }

    -- init global option menu
    _android._MENU_GLOBAL = _android._MENU_GLOBAL or
            {   {}
            ,   {nil, "ndk",        "kv", nil,          "The NDK Directory"             }
            ,   {nil, "ndk_sdkver", "kv", "auto",       "The SDK Version for NDK"       }
            ,   }

    -- get the option menu
    if action == "config" then
        return _android._MENU_CONFIG
    elseif action == "global" then
        return _android._MENU_GLOBAL
    end
end

-- return module: _android
return _android
