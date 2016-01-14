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
-- @file        mingw.lua
--

-- define module: mingw
local mingw = mingw or {}

-- load modules
local config    = require("base/config")

-- init host
mingw._HOST    = xmake._HOST

-- init os
mingw._OS       = "windows"

-- init architectures
mingw._ARCHS   = {"i386", "x86_64"}

-- make configure
function mingw.make(configs)

    -- init the file formats
    configs.formats         = {}
    configs.formats.static  = {"lib", ".a"}
    configs.formats.object  = {"",    ".o"}
    configs.formats.shared  = {"lib", ".so"}

    -- init the toolchains
    configs.tools           = {}
    configs.tools.make      = config.get("make")
    configs.tools.ccache    = config.get("__ccache")
    configs.tools.cc        = config.get("cc")
    configs.tools.cxx       = config.get("cxx")
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar") 
    configs.tools.sh        = config.get("sh") 
    configs.tools.ex        = config.get("ar") 
    configs.tools.sc        = config.get("sc") 

    -- init flags for architecture
    local archflags = nil
    local arch = config.get("arch")
    if arch then
        if arch == "x86_64" then archflags = "-m64"
        elseif arch == "i386" then archflags = "-m32"
        else archflags = "-arch " .. arch
        end
    end
    configs.cxflags     = { archflags }
    configs.asflags     = { archflags }
    configs.ldflags     = { archflags }
    configs.shflags     = { archflags }

end

-- get the option menu for action: xmake config or global
function mingw.menu(action)

    -- init config option menu
    mingw._MENU_CONFIG = mingw._MENU_CONFIG or {}

    -- init global option menu
    mingw._MENU_GLOBAL = mingw._MENU_GLOBAL or {}

    -- get the option menu
    if action == "config" then
        return mingw._MENU_CONFIG
    elseif action == "global" then
        return mingw._MENU_GLOBAL
    end
end

-- return module: mingw
return mingw
