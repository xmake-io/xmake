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
-- @file        windows.lua
--

-- define module: windows
local windows = windows or {}

-- load modules
local os            = require("base/os")
local config        = require("base/config")

-- init host
windows._HOST       = "windows"

-- init os
windows._OS         = "windows"

-- init architectures
windows._ARCHS      = {"x86", "x64", "amd64", "x86_amd64"}

-- enter the given environment
function windows._enter(name)

    -- check
    assert(name)

    -- get the pathes for the vs environment
    local old = nil
    local new = config.get("__vsenv_" .. name)
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- return the previous environment
    return old;
end

-- leave the given environment
function windows._leave(name, old)

    -- check
    assert(name)

    -- restore the previous environment
    if old then 
        os.setenv(name, old)
    end
end

-- enter environment
function windows.enter()

    -- enter the vs environment
    windows._pathes    = windows._enter("path")
    windows._libs      = windows._enter("lib")
    windows._includes  = windows._enter("include")
    windows._libpathes = windows._enter("libpath")

end

-- leave environment
function windows.leave()

    -- leave the vs environment
    windows._leave("path",       windows._pathes)
    windows._leave("lib",        windows._libs)
    windows._leave("include",    windows._includes)
    windows._leave("libpath",    windows._libpathes)

end
-- make configure
function windows.make(configs)

    -- init the file formats
    configs.formats             = {}
    configs.formats.static      = {"", ".lib"}
    configs.formats.object      = {"", ".obj"}
    configs.formats.shared      = {"", ".dll"}
    configs.formats.binary      = {"", ".exe"}

    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = config.get("make")
    configs.tools.cc        = config.get("cc")
    configs.tools.cxx       = config.get("cxx")
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar") 
    configs.tools.sh        = config.get("sh") 
    configs.tools.as        = config.get("as") 
    configs.tools.ex        = config.get("ex") 
end

-- get the option menu for action: xmake config or global
function windows.menu(action)

    -- init config option menu
    windows._MENU_CONFIG = windows._MENU_CONFIG or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
            ,   }

    -- init global option menu
    windows._MENU_GLOBAL = windows._MENU_GLOBAL or
            {   {}
            ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
            ,   }

    -- get the option menu
    if action == "config" then
        return windows._MENU_CONFIG
    elseif action == "global" then
        return windows._MENU_GLOBAL
    end
end


-- return module: windows
return windows
