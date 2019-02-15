--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        scopeinfo.lua
--

-- define module
local scopeinfo = scopeinfo or {}
local _instance = _instance or {}

-- load modules
local io    = require("base/io")
local os    = require("base/os")
local path  = require("base/path")
local table = require("base/table")
local utils = require("base/utils")

-- new an instance
function _instance.new(kind, info)
    local instance = table.inherit(_instance)
    instance._KIND = kind or "root"
    instance._INFO = info
    return instance
end

-- get the scope kind
function _instance:kind()
    return self._KIND
end

-- is root scope?
function _instance:is_root()
    return self:kind() == "root"
end

-- get all scope info
function _instance:info()
    return self._INFO
end

-- get the scope info from the given name
function _instance:get(name)
    return self._INFO[name]
end

-- set the value to the scope info
function _instance:set(name, value)
    self._INFO[name] = value
end

-- new an scope instance
function scopeinfo.new(name, info)
    return _instance.new(name, info)
end

-- return module
return scopeinfo
