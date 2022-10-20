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
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")

-- new an instance
function _instance.new(name, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = scopeinfo.new("component", {}, {interpreter = component._interpreter()})
    instance._PACKAGE = opt.package
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

-- get the it's package
function _instance:package()
    return self._PACKAGE
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

-- get on_component script
function _instance:_on_component()
    local script = self:package():get("component")
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then
        result = script[self:name()]
        result = result or script["__generic__"]
    end
    return result
end

-- load this component
function _instance:_load()
    local loaded = self._LOADED
    if not loaded then
        local script = self:_on_component()
        if script then
            local ok, errors = sandbox.load(script, self:package(), self)
            if not ok then
                os.raise("load component(%s) failed, %s", self:name(), errors or "unknown errors")
            end
        end
        self._LOADED = true
    end
end

-- the interpreter
function component._interpreter()
    local interp = component._INTERPRETER
    if not interp then
        interp = interpreter.new()
        interp:api_define(component.apis())
        interp:api_define(language.apis())
        component._INTERPRETER = interp
    end
    return interp
end

-- get component apis
function component.apis()
    return {
        values = {
            -- component.add_xxx
           "component.add_extsources"
        }
    }
end

-- new component
function component.new(name, opt)
    return _instance.new(name, opt)
end

-- return module
return component
