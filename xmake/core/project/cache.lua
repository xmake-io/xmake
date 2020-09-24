--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
local global        = require("base/global")

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

    -- memory cache?
    if scopename:startswith("memory.") then
        instance._CACHEDATA = instance._CACHEDATA or {__version = xmake._VERSION_SHORT}
        instances[scopename] = instance
        return instance
    end

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
    return self._CACHEDATA[name]
end

-- set the value
function cache:set(name, value)
    self._CACHEDATA[name] = value
end

-- clear all
function cache:clear()
    self._CACHEDATA = {__version = xmake._VERSION_SHORT}
end

-- flush to cache file
function cache:flush()

    -- flush the version
    self._CACHEDATA.__version = xmake._VERSION_SHORT

    -- memory cache? ignore it directly
    if not self._CACHEPATH then
        return
    end

    -- save to file
    local ok, errors = io.save(self._CACHEPATH, self._CACHEDATA)
    if not ok then
        os.raise(errors)
    end
end

-- return module
return cache._instance
