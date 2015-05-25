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
-- @file        _ios.lua
--

-- define module: _ios
local _ios = _ios or {}

-- init _ios
function _ios.init(configs)

    -- init the file name formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"",    ".dylib"}

    -- init the architecture scopes
    configs.archs = {}
    configs.archs.armv7      = {}
    configs.archs.armv7s     = {}
    configs.archs.arm64      = {}
end

-- get the option menu for action: xmake config or global
function _ios.menu(action)

    -- init config option menu
    _ios._MENU_CONFIG = _ios._MENU_CONFIG or
            {   {}   
            ,   {nil, "mm",             "kv", nil,          "The objc compiler"                     }
            ,   {nil, "mx",             "kv", nil,          "The objc/c++ compiler"                 }
            ,   {nil, "mxx",            "kv", nil,          "The objc++ compiler"                   }
            ,   {nil, "mflags",         "kv", nil,          "The objc compiler flags"               }
            ,   {nil, "mxflags",        "kv", nil,          "The objc/c++ compiler flags"           }
            ,   {nil, "mxxflags",       "kv", nil,          "The objc++ compiler flags"             }
            ,   {}
            ,   {nil, "xcode",          "kv", "/Applications/Xcode.app"
                                            ,               "The Xcode application directory"   }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK version for Xcode"         }
            ,   }

    -- init global option menu
    _ios._MENU_GLOBAL = _ios._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode",          "kv", "/Applications/Xcode.app"
                                            ,               "The Xcode application directory"   }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK version for Xcode"         }
            ,   }

    -- get the option menu
    if action == "config" then
        return _ios._MENU_CONFIG
    elseif action == "global" then
        return _ios._MENU_GLOBAL
    end
end


-- return module: _ios
return _ios
