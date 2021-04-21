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
    instance._DATA = {}
    return instance
end

-- get cache name
function _instance:name()
    return self._NAME
end

-- get cache data
function _instance:data()
    return self._DATA
end

-- get cache value in level/1
function _instance:get(key)
    return self._DATA[key]
end

-- get cache value in level/2
function _instance:get2(key1, key2)
    local value1 = self:get(key1)
    if value1 ~= nil then
        return value1[key2]
    end
end

-- get cache value in level/3
function _instance:get3(key1, key2, key3)
    local value2 = self:get2(key1, key2)
    if value2 ~= nil then
        return value2[key3]
    end
end

-- set cache value in level/1
function _instance:set(key, value)
    self._DATA[key] = value
end

-- set cache value in level/2
function _instance:set2(key1, key2, value2)
    local value1 = self:get(key1)
    if value1 == nil then
        value1 = {}
        self:set(key1, value1)
    end
    value1[key2] = value2
end

-- set cache value in level/3
function _instance:set3(key1, key2, key3, value3)
    local value2 = self:get2(key1, key2)
    if value2 == nil then
        value2 = {}
        self:set2(key1, key2, value2)
    end
    value2[key3] = value3
end

-- clear cache scopes
function _instance:clear()
    self._DATA = {}
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

-- get cache value in level/1
function memcache.get(cachename, key)
    return memcache.cache(cachename):get(key)
end

-- get cache value in level/2
function memcache.get2(cachename, key1, key2)
    return memcache.cache(cachename):get2(key1, key2)
end

-- get cache value in level/3
function memcache.get3(cachename, key1, key2, key3)
    return memcache.cache(cachename):get3(key1, key2, key3)
end

-- set cache value in level/1
function memcache.set(cachename, key, value)
    return memcache.cache(cachename):set(key, value)
end

-- set cache value in level/2
function memcache.set2(cachename, key1, key2, value)
    return memcache.cache(cachename):set2(key1, key2, value)
end

-- set cache value in level/3
function memcache.set3(cachename, key1, key2, key3, value)
    return memcache.cache(cachename):set3(key1, key2, key3, value)
end

-- clear the given cache, it will clear all caches if cache name is nil
function memcache.clear(cachename)
    local caches = memcache.caches()
    if caches then
        for _, cache in pairs(caches) do
            if cachename then
                if cache:name() == cachename then
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
