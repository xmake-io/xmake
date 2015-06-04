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
-- @file        msvc.lua
--

-- define module: msvc
local msvc = msvc or {}

-- load modules
local config        = require("base/config")

-- init host
msvc._HOST      = "windows"

-- init architectures
msvc._ARCHS     = {"x86", "x64"}

-- make configure
function msvc.make(configs)

    -- init the file formats
    configs.formats = {}
    configs.formats.static   = {"", ".lib"}
    configs.formats.object   = {"", ".obj"}
    configs.formats.shared   = {"", ".dll"}
    configs.formats.binary   = {"", ".exe"}

    -- init the toolchains
    configs.tools       = {}
    configs.tools.make  = "nmake"
    configs.tools.cc    = config.get("cc") or "cl"
    configs.tools.cxx   = config.get("cxx") or "cl"
    configs.tools.ld    = config.get("ld") or "link"
    configs.tools.ar    = config.get("ar") or "link"
    configs.tools.sh    = config.get("sh") or "link"

end

-- get the option menu for action: xmake config or global
function msvc.menu(action)

    -- init config option menu
    msvc._MENU_CONFIG = msvc._MENU_CONFIG or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
            ,   }

    -- init global option menu
    msvc._MENU_GLOBAL = msvc._MENU_GLOBAL or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
            ,   }

    -- get the option menu
    if action == "config" then
        return msvc._MENU_CONFIG
    elseif action == "global" then
        return msvc._MENU_GLOBAL
    end
end


-- return module: msvc
return msvc
