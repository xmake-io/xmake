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
-- @file        component.lua
--

-- define module
local component = component or {}
local _instance = _instance or {}

-- load modules
local os             = require("base/os")
local io             = require("base/io")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local option         = require("base/option")
local hashset        = require("base/hashset")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local memcache       = require("cache/memcache")
local config         = require("project/config")

-- new an instance
function _instance.new(name, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._NAME = name
    instance._INFO = info
    return instance
end

-- get the component name
function _instance:name()
    return self._NAME
end

-- get the type: component
function _instance:type()
    return "component"
end

-- get the component configuration
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to the component info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to the component info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    local conf = self._INFO:extraconf(name, item, key)
    if conf == nil and self:base() then
        conf = self:base():extraconf(name, item, key)
    end
    return conf
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    return self._INFO:extraconf_set(name, item, key, value)
end

-- new component
function component.new(name, info, opt)
    return _instance.new(name, info, opt)
end

-- return module
return component
