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
-- @file        scopeinfo.lua
--

-- define module
local scopeinfo = scopeinfo or {}
local _instance = _instance or {}

-- load modules
local io         = require("base/io")
local os         = require("base/os")
local path       = require("base/path")
local table      = require("base/table")
local utils      = require("base/utils")
local deprecated = require("base/deprecated")

-- new an instance
function _instance.new(kind, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._KIND = kind or "root"
    instance._INFO = info
    instance._INTERPRETER = opt.interpreter
    instance._DEDUPLICATE = opt.deduplicate
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
function _instance:_api_handle(name, values)
    local interp = self:interpreter()
    if interp then

        -- remove repeat first for each slice with deleted item (__remove_xxx)
        if self._DEDUPLICATE and not table.is_dictionary(values) then
            local policy = interp:deduplication_policy(name)
            if policy ~= false then
                local unique_func = policy == "toleft" and table.reverse_unique or table.unique
                values = unique_func(values, function (v) return type(v) == "string" and v:startswith("__remove_") end)
            end
        end

        -- filter values
        if self._ENABLE_FILTER then
            values = interp:_filter(values)
        end
    end

    -- unwrap it if be only one
    return table.unwrap(values)
end

-- save api source info, e.g. call api() in sourcefile:linenumber
function _instance:_api_save_sourceinfo_to_scope(scope, apiname, values)

    -- save api source info, e.g. call api() in sourcefile:linenumber
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

    -- @note we need mark table value as meta object to avoid wrap/unwrap
    -- if these values cannot be expanded, especially when there is only one value
    --
    -- e.g. target:set("shflags", {"-Wl,-exported_symbols_list", exportfile}, {force = true, expand = false})
    if extra_config and extra_config.expand == false then
        for _, value in ipairs(values) do
            table.wrap_lock(value)
        end
    else
        -- expand values
        values = table.join(table.unpack(values))
    end

    -- handle values
    local handled_values = self:_api_handle(name, values)

    -- save values
    if type(handled_values) == "table" and #handled_values == 0 then
        -- set("xx", nil)? remove it
        scope[name] = nil
    else
        scope[name] = handled_values
    end

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

    -- @note we need mark table value as meta object to avoid wrap/unwrap
    -- if these values cannot be expanded, especially when there is only one value
    --
    -- e.g. target:add("shflags", {"-Wl,-exported_symbols_list", exportfile}, {force = true, expand = false})
    if extra_config and extra_config.expand == false then
        for _, value in ipairs(values) do
            table.wrap_lock(value)
        end
    else
        -- expand values
        values = table.join(table.unpack(values))
    end

    -- save values
    scope[name] = self:_api_handle(name, table.join2(table.wrap(scope[name]), values))

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
    scope[name][key] = self:_api_handle(name, values)

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
    if scope[name][key] == nil then
        scope[name][key] = self:_api_handle(name, values)
    else
        scope[name][key] = self:_api_handle(name, table.join2(table.wrap(scope[name][key]), values))
    end

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

-- set the api dictionary to the scope info
function _instance:_api_set_dictionary(name, dict_or_key, value, extra_config)

    -- get the scope info
    local scope = self._INFO

    -- check
    if type(dict_or_key) == "table" then
        local dict = {}
        for k, v in pairs(dict_or_key) do
            dict[k] = self:_api_handle(name, v)
        end
        scope[name] = dict
    elseif type(dict_or_key) == "string" and value ~= nil then
        scope[name] = {[dict_or_key] = self:_api_handle(name, value)}
        -- save extra config
        if extra_config and table.is_dictionary(extra_config) then
            scope["__extra_" .. name] = scope["__extra_" .. name] or {}
            local extrascope = scope["__extra_" .. name]
            extrascope[dict_or_key] = extra_config
        end
    else
        -- error
        os.raise("%s:set(%s, ...): invalid value type!", self:kind(), name, type(dict))
    end
end

-- add the api dictionary to the scope info
function _instance:_api_add_dictionary(name, dict_or_key, value, extra_config)

    -- get the scope info
    local scope = self._INFO

    -- check
    scope[name] = scope[name] or {}
    if type(dict_or_key) == "table" then
        local dict = {}
        for k, v in pairs(dict_or_key) do
            dict[k] = self:_api_handle(name, v)
        end
        table.join2(scope[name], dict)
    elseif type(dict_or_key) == "string" and value ~= nil then
        scope[name][dict_or_key] = self:_api_handle(name, value)
        -- save extra config
        if extra_config and table.is_dictionary(extra_config) then
            scope["__extra_" .. name] = scope["__extra_" .. name] or {}
            local extrascope = scope["__extra_" .. name]
            extrascope[dict_or_key] = extra_config
        end
    else
        -- error
        os.raise("%s:add(%s, ...): invalid value type!", self:kind(), name, type(dict))
    end
end

-- set the api paths to the scope info
function _instance:_api_set_paths(name, ...)

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

    -- expand values
    values = table.join(table.unpack(values))

    -- translate paths
    local paths = interp:_api_translate_paths(values, "set_" .. name, 5)

    -- save values
    scope[name] = self:_api_handle(name, paths)

    -- save extra config
    if extra_config then
        scope["__extra_" .. name] = scope["__extra_" .. name] or {}
        local extrascope = scope["__extra_" .. name]
        for _, value in ipairs(paths) do
            extrascope[value] = extra_config
        end
    end

    -- save api source info, e.g. call api() in sourcefile:linenumber
    self:_api_save_sourceinfo_to_scope(scope, name, paths)
end

-- add the api paths to the scope info
function _instance:_api_add_paths(name, ...)

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

    -- expand values
    values = table.join(table.unpack(values))

    -- translate paths
    local paths = interp:_api_translate_paths(values, "add_" .. name, 5)

    -- save values
    scope[name] = self:_api_handle(name, table.join2(table.wrap(scope[name]), paths))

    -- save extra config
    if extra_config then
        scope["__extra_" .. name] = scope["__extra_" .. name] or {}
        local extrascope = scope["__extra_" .. name]
        for _, value in ipairs(paths) do
            extrascope[value] = extra_config
        end
    end

    -- save api source info, e.g. call api() in sourcefile:linenumber
    self:_api_save_sourceinfo_to_scope(scope, name, paths)
end

-- remove the api paths to the scope info (deprecated)
function _instance:_api_del_paths(name, ...)

    -- get the scope info
    local scope = self._INFO

    -- get interpreter
    local interp = self:interpreter()

    -- expand values
    values = table.join(...)

    -- it has been marked as deprecated
    deprecated.add("remove_" .. name .. "(%s)", "del_" .. name .. "(%s)", table.concat(values, ", "), table.concat(values, ", "))

    -- translate paths
    local paths = interp:_api_translate_paths(values, "del_" .. name, 5)

    -- mark these paths as deleted
    local paths_deleted = {}
    for _, pathname in ipairs(paths) do
        table.insert(paths_deleted, "__remove_" .. pathname)
    end

    -- save values
    scope[name] = self:_api_handle(name, table.join2(table.wrap(scope[name]), paths_deleted))

    -- save api source info, e.g. call api() in sourcefile:linenumber
    self:_api_save_sourceinfo_to_scope(scope, name, paths)
end

-- remove the api paths to the scope info
function _instance:_api_remove_paths(name, ...)

    -- get the scope info
    local scope = self._INFO

    -- get interpreter
    local interp = self:interpreter()

    -- expand values
    values = table.join(...)

    -- translate paths
    local paths = interp:_api_translate_paths(values, "remove_" .. name, 5)

    -- mark these paths as removed
    local paths_removed = {}
    for _, pathname in ipairs(paths) do
        table.insert(paths_removed, "__remove_" .. pathname)
    end

    -- save values
    scope[name] = self:_api_handle(name, table.join2(table.wrap(scope[name]), paths_removed))

    -- save api source info, e.g. call api() in sourcefile:linenumber
    self:_api_save_sourceinfo_to_scope(scope, name, paths)
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

-- set the api values to the scope info
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
            -- unknown api values? only set values
            self:_api_set_values(name, ...)
        end

    -- set array, e.g. set({{links = ..}, {links = ..}})
    elseif table.is_array(name) then
        local array = name
        for _, dict in ipairs(array) do
            for k, v in pairs(dict) do
                self:apival_set(k, table.unpack(table.wrap(v)))
            end
        end

    -- set dictionary, e.g. set({links = ..})
    elseif table.is_dictionary(name) then
        local dict = name
        for k, v in pairs(dict) do
            self:apival_set(k, table.unpack(table.wrap(v)))
        end
    elseif name ~= nil then
        os.raise("unknown type(%s) for %s:set(%s, ...)", type(name), self:kind(), name)
    end
end

-- add the api values to the scope info
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
            -- unknown api values? only add values
            self:_api_add_values(name, ...)
        end

    -- add array, e.g. add({{links = ..}, {links = ..}})
    elseif table.is_array(name) then
        local array = name
        for _, dict in ipairs(array) do
            for k, v in pairs(dict) do
                self:apival_add(k, table.unpack(table.wrap(v)))
            end
        end

    -- add dictionary, e.g. add({links = ..})
    elseif table.is_dictionary(name) then
        local dict = name
        for k, v in pairs(dict) do
            self:apival_add(k, table.unpack(table.wrap(v)))
        end
    elseif name ~= nil then
        os.raise("unknown type(%s) for %s:add(%s, ...)", type(name), self:kind(), name)
    end
end

-- remove the api values to the scope info (deprecated)
function _instance:apival_del(name, ...)
    if type(name) == "string" then
        local api_type = self:_api_type("del_" .. name)
        if api_type then
            local del_xxx = self["_api_remove_" .. api_type]
            if del_xxx then
                del_xxx(self, name, ...)
            else
                os.raise("unknown apitype(%s) for %s:del(%s, ...)", api_type, self:kind(), name)
            end
        else
            os.raise("unknown api(%s) for %s:del(%s, ...)", name, self:kind(), name)
        end
    elseif name ~= nil then
        -- TODO
        os.raise("cannot support to remove a dictionary!")
    end
end

-- remove the api values to the scope info
function _instance:apival_remove(name, ...)
    if type(name) == "string" then
        local api_type = self:_api_type("remove_" .. name)
        if api_type then
            local remove_xxx = self["_api_remove_" .. api_type]
            if remove_xxx then
                remove_xxx(self, name, ...)
            else
                os.raise("unknown apitype(%s) for %s:remove(%s, ...)", api_type, self:kind(), name)
            end
        else
            os.raise("unknown api(%s) for %s:remove(%s, ...)", name, self:kind(), name)
        end
    elseif name ~= nil then
        -- TODO
        os.raise("cannot support to remove a dictionary!")
    end
end

-- get the extra configuration
--
-- e.g.
--
-- add_includedirs("inc", {public = true})
--
-- function (target)
--     _instance:extraconf("includedirs", "inc", "public")  -> true
--     _instance:extraconf("includedirs", "inc")  -> {public = true}
--     _instance:extraconf("includedirs")  -> {inc = {public = true}}
-- end
--
function _instance:extraconf(name, item, key)

    -- get extra configurations
    local extraconfs = self._EXTRACONFS
    if not extraconfs then
        extraconfs = {}
        self._EXTRACONFS = extraconfs
    end

    -- get configuration
    local extraconf = extraconfs[name]
    if not extraconf then
        extraconf = self:get("__extra_" .. name)
        extraconfs[name] = extraconf
    end

    -- get configuration value
    local value = extraconf
    if item then
        value = extraconf and extraconf[item] or nil
        if value and key then
            value = value[key]
        end
    end
    return value
end

-- set the extra configuration
--
-- e.g.
--
-- add_includedirs("inc", {public = true})
--
-- function (target)
--     _instance:extraconf_set("includedirs", "inc", "public", true)
--     _instance:extraconf_set("includedirs", "inc", {public = true})
--     _instance:extraconf_set("includedirs", {inc = {public = true}})
-- end
--
function _instance:extraconf_set(name, item, key, value)
    if key ~= nil then
        local extraconf = self:get("__extra_" .. name) or {}
        if value ~= nil then
            extraconf[item] = extraconf[item] or {}
            extraconf[item][key] = value
        else
            extraconf[item] = key
        end
        self:set("__extra_" .. name, extraconf)
    else
        self:set("__extra_" .. name, item)
    end
end

-- clone a new instance from the current
function _instance:clone()
    return _instance.new(self:kind(), table.clone(self:info()), {interpreter = self:interpreter(), deduplicate = self._DEDUPLICATE, enable_filter = self._ENABLE_FILTER})
end

-- new a scope instance
function scopeinfo.new(...)
    return _instance.new(...)
end

-- return module
return scopeinfo
