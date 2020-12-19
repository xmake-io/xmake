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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        memcache.lua
--

-- define module: memcache
local memcache  = memcache or {}
local _instance = _instance or {}

-- load modules
local table = require("base/table")

-- new an instance
function _instance.new(name)
    local instance = table.inherit(_instance)
    instance._NAME = name
    instance._ITEMS = {}
    return instance
end

-- get cache name
function _instance:name()
    return self._NAME
end

-- get all cached items
function _instance:items()
    return self._ITEMS
end

-- get cache item value
function _instance:get(name)
    return self._ITEMS[name]
end

-- set cache item value
function _instance:set(name, value)
    self._ITEMS[name] = value
end

-- clear cache items
function _instance:clear()
    self._ITEMS = {}
end

-- get cache instance
function memcache.cache(cachename)
    local caches = memcache._CACHES
    if not caches then
        caches = {}
        memcache._CACHES = caches
    end
    local instance = caches[cachename]
    if not instance then
        instance = _instance.new(cachename)
        caches[cachename] = instance
    end
    return instance
end

-- get all caches
function memcache.caches()
    return memcache._CACHES
end

-- get cache item value
function memcache.get(cachename, name)
    return memcache.cache(cachename):get(name)
end

-- set cache item value
function memcache.set(cachename, name, value)
    return memcache.cache(cachename):set(name, value)
end

-- clear caches of the given scope name, it will clear all caches if pattern is nil
--
-- @code
-- memcache.clear() -- clear all caches
-- memcache.clear("cachescope") -- clear caches with `cachescope.*`
-- @endcode
--
function memcache.clear(scopename)
    local caches = memcache.caches()
    if caches then
        for _, cache in pairs(caches) do
            if scopename then
                if cache:name():startswith(scopename .. ".") then
                    cache:clear()
                end
            else
                cache:clear()
            end
        end
    end
end

-- return module: memcache
return memcache
