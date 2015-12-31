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
-- @file        linux.lua
--

-- define module: linux
local linux = linux or {}

-- load modules
local config    = require("base/config")

-- init host
linux._HOST    = "linux"

-- init os
linux._OS      = "linux"

-- init architectures
linux._ARCHS   = {"i386", "x86_64"}

-- make configure
function linux.make(configs)

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
    configs.tools.mm        = config.get("mm") 
    configs.tools.mxx       = config.get("mxx") 
    configs.tools.ld        = config.get("ld") 
    configs.tools.ar        = config.get("ar") 
    configs.tools.sh        = config.get("sh") 
    configs.tools.ex        = config.get("ar") 
    configs.tools.sc        = config.get("sc") 

    -- cross toolchains?
    if config.get("cross") then return end

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
    configs.mxflags     = { archflags }
    configs.asflags     = { archflags }
    configs.ldflags     = { archflags }
    configs.shflags     = { archflags }

    -- init linkdirs and includedirs
    configs.linkdirs    = {"/usr/lib", "/usr/local/lib"}
    configs.includedirs = {"/usr/include", "/usr/local/include"}

end

-- get the option menu for action: xmake config or global
function linux.menu(action)

    -- init config option menu
    linux._MENU_CONFIG = linux._MENU_CONFIG or {}

    -- init global option menu
    linux._MENU_GLOBAL = linux._MENU_GLOBAL or {}

    -- get the option menu
    if action == "config" then
        return linux._MENU_CONFIG
    elseif action == "global" then
        return linux._MENU_GLOBAL
    end
end

-- return module: linux
return linux
