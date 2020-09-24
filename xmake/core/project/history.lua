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
-- @file        history.lua
--

-- define module: history
local history = history or {}

-- load modules
local os                = require("base/os")
local io                = require("base/io")
local table             = require("base/table")
local utils             = require("base/utils")
local string            = require("base/string")
local cache             = require("project/cache")

-- the cache instance
--
-- @param scopename     local.xxxx
--                      global.xxxx
--
function history._instance(scopename)

    -- check
    assert(scopename)

    -- init instances
    history._INSTANCES = history._INSTANCES or {}
    local instances = history._INSTANCES

    -- this instance has been initialized?
    if instances[scopename] then
        return instances[scopename]
    end

    -- init instance
    local instance = table.inherit(history)

    -- init cache
    instance._CACHE = cache(scopename)

    -- save instance
    instances[scopename] = instance

    -- ok
    return instance
end

-- save history
function history:save(key, value)

    -- check
    assert(key and value ~= nil)

    -- load history values first
    local values = self:load(key) or {}

    -- remove the oldest value if be full
    if #values > 64 then
        table.remove(values, 1)
    end

    -- append this value
    table.insert(values, value)

    -- save history
    self._CACHE:set(key, values)
    self._CACHE:flush()
end

-- load history
function history:load(key)
    return self._CACHE:get(key)
end

-- return module: history
return history._instance
