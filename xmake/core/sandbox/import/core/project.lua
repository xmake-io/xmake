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
-- @file        project.lua
--

-- define module
local sandbox_project = sandbox_project or {}

-- load modules
local rule      = require("base/rule")
local config    = require("base/config")
local project   = require("base/project")

-- get the build directory
function sandbox_project.buildir()

    -- get it 
    return config.get("buildir")
end

-- get the project directory
function sandbox_project.projectdir()

    -- get it 
    return xmake._PROJECT_DIR
end

-- get the current platform
function sandbox_project.plat()

    -- get it 
    return config.get("plat")
end

-- get the current architecture
function sandbox_project.arch()

    -- get it 
    return config.get("arch")
end

-- get the current mode
function sandbox_project.mode()

    -- get it 
    return config.get("mode")
end

-- get the menu
function sandbox_project.menu()

    -- get it 
    return project.menu()
end

-- return module
return sandbox_project
