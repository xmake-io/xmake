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

-- load modules
local config        = require("base/config")

-- init host
_windows._HOST      = "windows"

-- init architectures
_windows._ARCHS     = {"x86", "x64"}

-- init maker
_windows._MAKER     = require("platform/windows/_maker")

-- init prober
_windows._PROBER    = require("platform/windows/_prober")

-- make configure
function _windows.make(configs)

    -- init the file name format
    configs.format = {}
    configs.format.static   = {"", ".lib"}
    configs.format.object   = {"", ".obj"}
    configs.format.shared   = {"", ".dll"}
    configs.format.binary   = {"", ".exe"}

    -- init the compiler
    configs.compiler = {}
    configs.compiler.cc     = config.get("cc") or "cl.exe"
    configs.compiler.cxx    = config.get("cxx") or "cl.exe"

    -- init the linker
    configs.linker = {}
    configs.linker.binary   = config.get("ld") or "link.exe"
    configs.linker.static   = config.get("ar") or "link.exe"
    configs.linker.shared   = config.get("sh") or "link.exe"

end

-- get the option menu for action: xmake config or global
function _windows.menu(action)

    -- init config option menu
    _windows._MENU_CONFIG = _windows._MENU_CONFIG or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
            ,   }

    -- init global option menu
    _windows._MENU_GLOBAL = _windows._MENU_GLOBAL or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
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
