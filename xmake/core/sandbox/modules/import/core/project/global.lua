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
-- @file        global.lua
--

-- define module
local sandbox_core_project_global = sandbox_core_project_global or {}

-- load modules
local global    = require("project/global")
local raise     = require("sandbox/modules/raise")

-- get the configure
function sandbox_core_project_global.get(name)

    -- get it
    return global.get(name)
end

-- set the configure 
function sandbox_core_project_global.set(name, value)

    -- set it
    global.set(name, value)
end

-- get the configure directory
function sandbox_core_project_global.directory()

    -- get it
    local dir = global.directory()
    assert(dir)

    -- ok?
    return dir
end


-- return module
return sandbox_core_project_global
