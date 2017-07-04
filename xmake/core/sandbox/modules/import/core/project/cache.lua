--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cache.lua
--

-- define module
local sandbox_core_project_cache = sandbox_core_project_cache or {}

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

