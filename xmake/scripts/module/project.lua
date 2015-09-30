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
-- @file        project.lua
--

-- define module: project
local project = project or {}

-- load modules
local rule      = require("base/rule")
local config    = require("base/config")

-- get the build directory
function project.buildir()

    -- get it 
    return config.get("buildir")
end

-- get the project directory
function project.projectdir()

    -- get it 
    return xmake._PROJECT_DIR
end

-- get the log file
function project.logfile()

    -- get it 
    return rule.logfile()
end

-- get the current platform
function project.plat()

    -- get it 
    return config.get("plat")
end

-- get the current architecture
function project.arch()

    -- get it 
    return config.get("arch")
end

-- get the current mode
function project.mode()

    -- get it 
    return config.get("mode")
end

-- return module: project
return project
