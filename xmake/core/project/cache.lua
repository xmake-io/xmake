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
-- @file        cache.lua
--

-- define module
local cache = cache or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local utils         = require("base/utils")
local config        = require("project/config")
local global        = require("project/global")

-- the cache instance
--
-- @param scopename     local.xxxx
--                      global.xxxx
--
function cache._instance(scopename)

    -- check
    assert(scopename)

    -- init instances
    cache._INSTANCES = cache._INSTANCES or {}
    local instances = cache._INSTANCES

    -- this instance has been initialized?
    if instances[scopename] then
        return instances[scopename]
    end

    -- init instance
    local instance = table.inherit(cache)

    -- check scopename
    if not scopename:find("local%.") and not scopename:find("global%.") then
        os.raise("invalid cache scope: %s", scopename)
    end

    -- make the cache path
    local cachepath = (scopename:gsub("%.", "/"))
    cachepath = (cachepath:gsub("^local%/", path.join(config.directory(), "cache") .. "/"))
    cachepath = (cachepath:gsub("^global%/", path.join(global.directory(), "cache") .. "/"))

    -- save the cache path 
    instance._CACHEPATH = cachepath

    -- load the cache data 
    local results = io.load(cachepath)
    if results then
        instance._CACHEDATA = results
    end
    instance._CACHEDATA = instance._CACHEDATA or {__version = xmake._VERSION_SHORT}

    -- save instance
    instances[scopename] = instance

    -- ok
    return instance
end

-- get the value
function cache:get(name)

    -- get it
    return self._CACHEDATA[name]
end

-- set the value
function cache:set(name, value)

    -- set it
    self._CACHEDATA[name] = value
end

-- clear all
function cache:clear()

    -- clear it
    self._CACHEDATA = {__version = xmake._VERSION_SHORT}
end

-- flush to cache file
function cache:flush()

    -- flush the version 
    self._CACHEDATA.__version = xmake._VERSION_SHORT

    -- save to file
    return io.save(self._CACHEPATH, self._CACHEDATA) 
end

-- return module
return cache._instance
