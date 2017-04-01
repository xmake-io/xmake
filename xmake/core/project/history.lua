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

-- get cache
function history._cache()

    -- get it from cache first if exists
    if history._CACHE then
        return history._CACHE
    end

    -- init cache
    history._CACHE = cache("local.history")

    -- ok
    return history._CACHE
end

-- save history
function history.save(key, value)

    -- check
    assert(key and value ~= nil)

    -- load history values first
    local values = history.load(key) or {}

    -- remove the oldest value if be full
    if #values > 64 then
        table.remove(values, 1)
    end

    -- append this value
    table.insert(values, value)

    -- save history
    history._cache():set(key, values)
    history._cache():flush()
end

-- load history 
function history.load(key)

    -- load it
    return history._cache():get(key)
end

-- return module: history
return history
