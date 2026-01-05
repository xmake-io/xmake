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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        scheme.lua
--

-- @ref         https://github.com/xmake-io/xmake/issues/7184
-- @note        This module provides scheme management for packages,
--              allowing custom download schemes and configurations
--              to be defined and applied to package management.

-- define module
local scheme = scheme or {}
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
    instance._INFO    = scopeinfo.new("scheme", {}, {interpreter = scheme._interpreter()})
    instance._PACKAGE = opt.package
    return instance
end

-- get the scheme name
function _instance:name()
    return self._NAME
end

-- get the type: scheme
function _instance:type()
    return "scheme"
end

-- get the it's package
function _instance:package()
    return self._PACKAGE
end

-- get the scheme configuration
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to scheme info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to scheme info
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

-- get on_scheme script
function _instance:_on_scheme()
    local script = self:package():get("scheme")
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then
        result = script[self:name()]
        result = result or script["__generic__"]
    end
    return result
end

-- load this scheme
function _instance:_load()
    local loaded = self._LOADED
    if not loaded then
        local script = self:_on_scheme()
        if script then
            local ok, errors = sandbox.load(script, self:package(), self)
            if not ok then
                os.raise("load scheme(%s) failed, %s", self:name(), errors or "unknown errors")
            end
        end
        self._LOADED = true
    end
end

-- interpreter
function scheme._interpreter()
    local interp = scheme._INTERPRETER
    if not interp then
        interp = interpreter.new()
        interp:api_define(scheme.apis())
        scheme._INTERPRETER = interp
    end
    return interp
end

-- get scheme apis
function scheme.apis()
    return {
        values = {
            -- scheme.set_xxx
            "scheme.set_urls",
            "scheme.set_policy",
            -- scheme.add_xxx
            "scheme.add_urls",
            "scheme.add_patches",
            "scheme.add_resources",
            "scheme.add_versionfiles",
            "scheme.add_versions"
        },
        keyvalues = {
            -- scheme.set_xxx
            "scheme.set_policy"
            -- scheme.add_xxx
        ,   "scheme.add_patches"
        ,   "scheme.add_resources"
        },
        paths = {
            -- scheme.add_xxx
            "scheme.add_versionfiles"
        },
        dictionary = {
            -- scheme.add_xxx
            "scheme.add_versions"
        }
    }
end

-- new scheme
function scheme.new(name, opt)
    return _instance.new(name, opt)
end

-- return module
return scheme
