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
-- @file        _linux.lua
--

-- define module: _linux
local _linux = _linux or {}

-- load modules
local config    = require("base/config")

-- init host
_linux._HOST    = "linux"

-- init architectures
_linux._ARCHS   = {"x86", "x64"}

-- init prober
_linux._PROBER  = require("platform/linux/_prober")

-- make configure
function _linux.make(configs)

    -- init the file name formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"",    ".so"}
end

-- get the option menu for action: xmake config or global
function _linux.menu(action)

    -- init config option menu
    _linux._MENU_CONFIG = _linux._MENU_CONFIG or
            {   {}
            ,   {nil, "ar",         "kv", "ar",         "The Library Creator"           }
            ,   {nil, "arflags",    "kv", nil,          "The Library Creator Flags"     }
            }

    -- init global option menu
    _linux._MENU_GLOBAL = _linux._MENU_GLOBAL or {}

    -- get the option menu
    if action == "config" then
        return _linux._MENU_CONFIG
    elseif action == "global" then
        return _linux._MENU_GLOBAL
    end
end

-- return module: _linux
return _linux
