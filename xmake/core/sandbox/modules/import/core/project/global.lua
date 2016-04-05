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
local platform  = require("platform/platform")
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

-- dump the configure
function sandbox_core_project_global.dump()

    -- dump it
    global.dump()
end

-- load the configure
function sandbox_core_project_global.load()

    -- load it
    local ok, errors = global.load()
    if not ok then
        raise(errors)
    end
end

-- save the configure
function sandbox_core_project_global.save()

    -- save it
    local ok, errors = global.save()
    if not ok then
        raise(errors)
    end
end

-- probe the configure
function sandbox_core_project_global.probe()

    -- probe it
    if not platform.probe(true) then
        raise("probe the global configure failed!")
    end
end

-- get all options
function sandbox_core_project_global.options()
        
    -- get it
    return global.options()
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
