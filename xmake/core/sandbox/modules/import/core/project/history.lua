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

-- define module
local sandbox_core_project_history = sandbox_core_project_history or {}

-- load modules
local os        = require("base/os")
local io        = require("base/io")
local table     = require("base/table")
local option    = require("base/option")
local string    = require("base/string")
local history   = require("project/history")
local raise     = require("sandbox/modules/raise")
local instance  = nil

-- enter the history scope
function sandbox_core_project_history.enter(scopename)

    -- get the history instance
    instance = history(scopename)
end

-- load the history data 
function sandbox_core_project_history.load(key)

    -- check
    assert(instance)

    -- load it
    return instance:load(key)
end

-- save the history data
function sandbox_core_project_history.save(key, value)

    -- check
    assert(instance)

    -- save it
    instance:save(key, value)
end

-- return module
return sandbox_core_project_history
