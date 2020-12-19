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
    local instance   = table.inherit(_instance)
    instance._NAME   = name
    instance._SCOPES = {}
    return instance
end

-- get cache name
function _instance:name()
    return self._NAME
end

-- get all cache scopes
function _instance:scopes()
    return self._SCOPES
end

-- get cache scope
function _instance:scope(scopename)
    return self._SCOPES[scopename]
end

-- set cache scope
function _instance:scope_set(scopename, scope)
    self._SCOPES[scopename] = scope
end

-- get cache value in the given scope
function _instance:value(scopename, name)
    local scope = self._SCOPES[scopename]
    if scope then
        return scope[name]
    end
end

-- set cache value in the given scope
function _instance:value_set(scopename, name, value)
    local scope = self._SCOPES[scopename]
    if not scope then
        scope = {}
        self._SCOPES[scopename] = scope
    end
    scope[name] = value
end

-- add cache value in the given scope
function _instance:value_add(scopename, name, value)
    local scope = self._SCOPES[scopename]
    if not scope then
        scope = {}
        self._SCOPES[scopename] = scope
    end
    scope[name] = table.unwrap(table.join(scope[name] or {}, value))
end

-- clear cache scopes
function _instance:clear()
    self._SCOPES = {}
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

-- get cache scopes
function memcache.scopes(cachename)
    return memcache.cache(cachename):scopes()
end

-- get cache scope
function memcache.scope(cachename, scopename)
    return memcache.cache(cachename):scope(scopename)
end

-- set cache scope
function memcache.scope_set(cachename, scopename, scope)
    return memcache.cache(cachename):scope_set(scopename, scope)
end

-- get cache value in the given scope
function memcache.value(cachename, scopename, name)
    return memcache.cache(cachename):value(scopename, name)
end

-- set cache value in the given scope
function memcache.value_set(cachename, scopename, name, value)
    return memcache.cache(cachename):value_set(scopename, name, value)
end

-- add cache value in the given scope
function memcache.value_add(cachename, scopename, name, value)
    return memcache.cache(cachename):value_add(scopename, name, value)
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
