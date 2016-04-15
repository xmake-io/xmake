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
local sandbox_core_project_project = sandbox_core_project_project or {}

-- load modules
local config    = require("project/config")
local project   = require("project/project")
local raise     = require("sandbox/modules/raise")

-- load project
function sandbox_core_project_project.load()

    -- load it
    local ok, errors = project.load()
    if not ok then
        raise(errors)
    end
end

-- check project options
function sandbox_core_project_project.check()

    -- check it
    local ok, errors = project.check()
    if not ok then
        raise(errors)
    end
end

-- get the given target
function sandbox_core_project_project.target(targetname)

    -- get it
    return project.target(targetname)
end

-- get the all targets
function sandbox_core_project_project.targets()

    -- get targets
    local targets = project.targets()
    assert(targets)

    -- ok
    return targets
end

-- get the project file
function sandbox_core_project_project.file()

    -- get it
    return xmake._PROJECT_FILE
end

-- get the project directory
function sandbox_core_project_project.directory()

    -- get it
    return xmake._PROJECT_DIR
end

-- get the project mtimes
function sandbox_core_project_project.mtimes()

    -- get it
    return project.mtimes()
end

-- return module
return sandbox_core_project_project
