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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        menu.lua
--

-- define module
local sandbox_core_platform_menu = sandbox_core_platform_menu or {}

-- load modules
local platform = require("platform/platform")

-- get the all platforms
function sandbox_core_platform_menu.plats()

    -- get it 
    local plats = platform.plats()
    assert(plats)

    -- ok
    return plats
end

-- get the all architectures for the given platform
function sandbox_core_platform_menu.archs(plat)

    -- get it 
    local archs = platform.archs(plat)
    assert(archs)

    -- ok
    return archs
end

-- get the platform menu options for global
function sandbox_core_platform_menu.options_global()

    -- get it 
    return platform.menu("global")
end

-- get the platform menu options for config
function sandbox_core_platform_menu.options_config()

    -- get it 
    return platform.menu("config")
end

-- return module
return sandbox_core_platform_menu
