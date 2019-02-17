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
function _instance.new(kind, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._KIND = kind or "root"
    instance._INFO = info
    instance._INTERPRETER   = opt.interpreter
    instance._REMOVE_REPEAT = opt.remove_repeat
    instance._ENABLE_FILTER = opt.enable_filter
    return instance
end

-- get apis
function _instance:_apis()
    local interp = self:interpreter()
    if interp then
        return interp:api_definitions()
    end
end

-- get the given api type
function _instance:_api_type(name)
    local apis = self:_apis()
    if apis then
        return apis[self:kind() .. '.' .. name]
    end
end

-- handle the api values
function _instance:_api_handle(values)
    local interp = self:interpreter()
    if interp then
        values = interp:_handle(values, self._REMOVE_REPEAT, self._ENABLE_FILTER)
    end
    return values
end

-- save api source info, .e.g call api() in sourcefile:linenumber
function _instance:_api_save_sourceinfo_to_scope(scope, apiname, values)

    -- save api source info, .e.g call api() in sourcefile:linenumber
    local sourceinfo = debug.getinfo(5, "Sl")
    if sourceinfo then
        scope["__sourceinfo_" .. apiname] = scope["__sourceinfo_" .. apiname] or {}
        local sourcescope = scope["__sourceinfo_" .. apiname]
        for _, value in ipairs(values) do
            if type(value) == "string" then
                sourcescope[value] = {file = sourceinfo.short_src or sourceinfo.source, line = sourceinfo.currentline}
            end
        end
    end
end

-- set the api values to the scope info
function _instance:_api_set_values(name, ...)

    -- get the scope info
    local scope = self._INFO

    -- get extra config
    local values = {...}
    local extra_config = values[#values]
    if table.is_dictionary(extra_config) then 
        table.remove(values)
    else
        extra_config = nil
    end

    -- handle values
    local handled_values = self:_api_handle(values)

    -- save values
    scope[name] = handled_values

    -- save extra config
    if extra_config then
        scope["__extra_" .. name] = scope["__extra_" .. name] or {}
        local extrascope = scope["__extra_" .. name]
        for _, value in ipairs(values) do
            extrascope[value] = extra_config
        end
    end
end

-- add the api values to the scope info
function _instance:_api_add_values(name, ...)

    -- get the scope info
    local scope = self._INFO

    -- get extra config
    local values = {...}
    local extra_config = values[#values]
    if table.is_dictionary(extra_config) then 
        table.remove(values)
    else
        extra_config = nil
    end

    -- save values
    scope[name] = self:_api_handle(table.join2(table.wrap(scope[name]), values))

    -- save extra config
    if extra_config then
        scope["__extra_" .. name] = scope["__extra_" .. name] or {}
        local extrascope = scope["__extra_" .. name]
        for _, value in ipairs(values) do
            extrascope[value] = extra_config
        end
    end
end

-- set the api key-values to the scope info
function _instance:_api_set_keyvalues(name, key, ...)

    -- get the scope info
    local scope = self._INFO

    -- get extra config
    local values = {...}
    local extra_config = values[#values]
    if table.is_dictionary(extra_config) then 
        table.remove(values)
    else
        extra_config = nil
    end

    -- save values to "name"
    scope[name] = scope[name] or {}
    scope[name][key] = self:_api_handle(values)

    -- save values to "name.key"
    local name_key = name .. "." .. key
    scope[name_key] = scope[name][key]

    -- fix override attributes
    scope["__override_" .. name] = false
    scope["__override_" .. name_key] = true

    -- save extra config
    if extra_config then
        scope["__extra_" .. name_key] = scope["__extra_" .. name_key] or {}
        local extrascope = scope["__extra_" .. name_key]
        for _, value in ipairs(values) do
            extrascope[value] = extra_config
        end
    end
end

-- add the api key-values to the scope info
function _instance:_api_add_keyvalues(name, key, ...)

    -- get the scope info
    local scope = self._INFO

    -- get extra config
    local values = {...}
    local extra_config = values[#values]
    if table.is_dictionary(extra_config) then 
        table.remove(values)
    else
        extra_config = nil
    end

    -- save values to "name"
    scope[name] = scope[name] or {}
    scope[name][key] = self:_api_handle(table.join2(table.wrap(scope[name][key]), values))

    -- save values to "name.key"
    local name_key = name .. "." .. key
    scope[name_key] = scope[name][key]

    -- save extra config
    if extra_config then
        scope["__extra_" .. name_key] = scope["__extra_" .. name_key] or {}
        local extrascope = scope["__extra_" .. name_key]
        for _, value in ipairs(values) do
            extrascope[value] = extra_config
        end
    end
end

-- set the api pathes to the scope info
function _instance:_api_set_pathes(name, ...)

    -- get the scope info
    local scope = self._INFO
end

-- add the api pathes to the scope info
function _instance:_api_add_pathes(name, ...)

    -- get the scope info
    local scope = self._INFO

    -- get interpreter
    local interp = self:interpreter()

    -- get extra config
    local values = {...}
    local extra_config = values[#values]
    if table.is_dictionary(extra_config) then 
        table.remove(values)
    else
        extra_config = nil
    end

    -- translate pathes
    local pathes = interp:_api_translate_pathes(values)

    -- save values
    scope[name] = self:_api_handle(table.join2(table.wrap(scope[name]), pathes))

    -- save extra config
    if extra_config then
        scope["__extra_" .. name] = scope["__extra_" .. name] or {}
        local extrascope = scope["__extra_" .. name]
        for _, value in ipairs(pathes) do
            extrascope[value] = extra_config
        end
    end

    -- save api source info, .e.g call api() in sourcefile:linenumber
    self:_api_save_sourceinfo_to_scope(scope, name, pathes)
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

-- get interpreter
function _instance:interpreter()
    return self._INTERPRETER
end

-- get the scope info from the given name
function _instance:get(name)
    return self._INFO[name]
end

-- set the value to the scope info
function _instance:set(name, value)
    self._INFO[name] = value
end

-- set the api value to the scope info
function _instance:apival_set(name, ...)
    if type(name) == "string" then
        local api_type = self:_api_type("set_" .. name)
        if api_type then
            local set_xxx = self["_api_set_" .. api_type]
            if set_xxx then
                set_xxx(self, name, ...)
            else
                os.raise("unknown apitype(%s) for %s:set(%s, ...)", api_type, self:kind(), name)
            end
        else
            os.raise("unknown api(%s) for %s:set(%s, ...)", name, self:kind(), name)
        end
    else
        -- TODO
    end
end

-- add the api value to the scope info
function _instance:apival_add(name, ...)
    if type(name) == "string" then
        local api_type = self:_api_type("add_" .. name)
        if api_type then
            local add_xxx = self["_api_add_" .. api_type]
            if add_xxx then
                add_xxx(self, name, ...)
            else
                os.raise("unknown apitype(%s) for %s:add(%s, ...)", api_type, self:kind(), name)
            end
        else
            os.raise("unknown api(%s) for %s:add(%s, ...)", name, self:kind(), name)
        end
    else
        -- TODO
    end
end

-- new an scope instance
function scopeinfo.new(...)
    return _instance.new(...)
end

-- return module
return scopeinfo
