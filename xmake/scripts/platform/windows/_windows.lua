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
-- @file        _windows.lua
--

-- define module: _windows
local _windows = _windows or {}

-- init _windows
function _windows.init(configs)

    -- init the file name formats
    configs.formats = {}
    configs.formats.static   = {"", ".lib"}
    configs.formats.object   = {"", ".obj"}
    configs.formats.shared   = {"", ".dll"}
    configs.formats.console  = {"", ".exe"}

    -- init the architecture scopes
    configs.archs = {}
    configs.archs.x86 = {}
    configs.archs.x64 = {}
end

-- get the option menu for action: xmake config or global
function _windows.menu(action)

    -- init config option menu
    _windows._MENU_CONFIG = _windows._MENU_CONFIG or
            {   {}
            ,   {nil, "vs",         "kv", "auto",       "The Microsoft Visual Studio directory"         }
            ,   {nil, "vs_sdk",     "kv", "auto",       "The Microsoft Visual Studio SDK directory"     }
            ,   }

    -- init global option menu
    _windows._MENU_GLOBAL = _windows._MENU_GLOBAL or
            {   {}
            ,   {nil, "vs",         "kv", "auto",       "The Microsoft Visual Studio directory"         }
            ,   {nil, "vs_sdk",     "kv", "auto",       "The Microsoft Visual Studio SDK directory"     }
            ,   }

    -- get the option menu
    if action == "config" then
        return _windows._MENU_CONFIG
    elseif action == "global" then
        return _windows._MENU_GLOBAL
    end
end


-- return module: _windows
return _windows
