--!The Make-like Build Utility based on Lua
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
-- @file        cache.lua
--

-- define module
local sandbox_core_project_cache = {}

-- load modules
local cache     = require("project/cache")
local raise     = require("sandbox/modules/raise")
local instance  = nil

-- enter the cache scope
function sandbox_core_project_cache.enter(scopename)

    -- get the cache instance
    instance = cache(scopename)
end

-- get the value
function sandbox_core_project_cache.get(name)

    -- check
    assert(instance)

    -- get it
    return instance:get(name)
end

-- set the value
function sandbox_core_project_cache.set(name, value)

    -- check
    assert(instance)

    -- set it
    instance:set(name, value)
end

-- clear all
function sandbox_core_project_cache:clear()

    -- check
    assert(instance)

    -- clear it
    instance:clear()
end

-- flush to sandbox_core_project_cache file
function sandbox_core_project_cache:flush()

    -- check
    assert(instance)

    -- flush it
    local ok, errors = instance:flush()
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_project_cache

