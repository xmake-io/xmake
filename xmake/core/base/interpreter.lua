--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        interpreter.lua
--

-- define module: interpreter
local interpreter = interpreter or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")
local sandbox   = require("base/sandbox")

-- traceback
function interpreter._traceback(errors)

    -- init results
    local results = ""
    if errors then
        results = errors .. "\n"
    end
    results = results .. "stack traceback:\n"

    -- make results
    local level = 2    
    while true do    

        -- get debug info
        local info = debug.getinfo(level, "Sln")

        -- end?
        if not info or (info.name and info.name == "xpcall") then
            break
        end

        -- function?
        if info.what == "C" then
            results = results .. string.format("    [C]: in function '%s'\n", info.name)
        elseif info.name then 
            results = results .. string.format("    [%s:%d]: in function '%s'\n", info.short_src, info.currentline, info.name)    
        elseif info.what == "main" then
            results = results .. string.format("    [%s:%d]: in main chunk\n", info.short_src, info.currentline)    
            break
        else
            results = results .. string.format("    [%s:%d]:\n", info.short_src, info.currentline)    
        end

        -- next
        level = level + 1    
    end    

    -- ok?
    return results
end

-- register api: xxx_apiname()
function interpreter._api_register_xxx_scope(self, action, apifunc, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(action and apifunc)

    -- done
    for _, apiname in ipairs({...}) do

        -- check
        assert(apiname)

        -- register scope api
        self:api_register(action .. "_" .. apiname, function (self, ...) 
       
            -- check
            assert(self and self._PRIVATE and apiname)

            -- the scopes
            local scopes = self._PRIVATE._SCOPES
            assert(scopes)

            -- call function
            return apifunc(self, scopes, apiname, ...) 
        end)
    end
end

-- register api: xxx_values()
function interpreter._api_register_xxx_values(self, scope_kind, action, prefix, apifunc, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(action and apifunc)

    -- uses the root scope kind if no scope kind
    if not scope_kind then
        scope_kind = "__rootkind"
    end

    -- define implementation
    local implementation = function (self, scopes, apiname, ...)

        -- init root scopes
        scopes._ROOT = scopes._ROOT or {}

        -- init current root scope
        local root = scopes._ROOT[scope_kind] or {}
        scopes._ROOT[scope_kind] = root

        -- clear the current scope if be not belong to the current scope kind 
        if scopes._CURRENT and scopes._CURRENT_KIND ~= scope_kind then
            scopes._CURRENT = nil
        end

        -- the current scope
        local scope = scopes._CURRENT or root
        assert(scope)

        -- enter subscope and set values? override it
        if scopes._CURRENT and apiname and action == "set" then
            scope["__override_" .. apiname] = true
        end

        -- call function
        return apifunc(self, scope, apiname, ...) 
    end

    -- register implementation
    if prefix then action = action .. "_" .. prefix end
    self:_api_register_xxx_scope(action, implementation, ...)
end

-- translate api pathes 
function interpreter._api_translate_pathes(self, ...)

    -- check
    assert(self and self._PRIVATE)

    -- the current file 
    local curfile = self._PRIVATE._CURFILE
    assert(curfile)

    -- the current directory
    local curdir = path.directory(curfile)
    assert(curdir)

    -- get all pathes
    local pathes = table.join(...)

    -- translate the relative path 
    local results = {}
    for _, p in ipairs(pathes) do
        if not p:find("^%s-%$%(.-%)") and not path.is_absolute(p) then
            table.insert(results, path.relative(path.absolute(p, curdir), self._PRIVATE._ROOTDIR))
        else
            table.insert(results, p)
        end
    end

    -- ok?
    return results
end

-- the builtin api: add_subdirs() or add_subfiles()
function interpreter._api_builtin_add_subdirfiles(self, isdirs, ...)

    -- check
    assert(self and self._PRIVATE and self._PRIVATE._ROOTDIR and self._PRIVATE._MTIMES)

    -- the current file 
    local curfile = self._PRIVATE._CURFILE
    assert(curfile)

    -- get all subpathes 
    local subpathes = self:_api_translate_pathes(...)

    -- match all subpathes
    local subpathes_matched = {}
    for _, subpath in ipairs(subpathes) do
        local files = os.match(subpath, isdirs)
        if files then table.join2(subpathes_matched, files) end
    end

    -- done
    for _, subpath in ipairs(subpathes_matched) do
        if subpath and type(subpath) == "string" then

            -- the file path
            local file = subpath
            if isdirs then
                file = path.join(subpath, path.filename(curfile))
            end

            -- get the absolute file path
            if not path.is_absolute(file) then
                file = path.absolute(file, self._PRIVATE._ROOTDIR)
            end

            -- update the current file
            self._PRIVATE._CURFILE = file

            -- load the file script
            local script, errors = loadfile(file)
            if script then

                -- bind public scope
                setfenv(script, self._PUBLIC)

                -- done interpreter
                local ok, errors = xpcall(script, interpreter._traceback)
                if not ok then
                    utils.error(errors)
                    utils.abort()
                end

                -- get mtime of the file
                self._PRIVATE._MTIMES[path.relative(file, self._PRIVATE._ROOTDIR)] = os.mtime(file)
            else
                utils.error(errors)
                utils.abort()
            end
        end
    end

    -- restore the current file 
    self._PRIVATE._CURFILE = curfile
end

-- clear results
function interpreter._clear(self)

    -- check
    assert(self and self._PRIVATE)

    -- clear it
    self._PRIVATE._SCOPES = {}
    self._PRIVATE._MTIMES = {}
end

-- filter values
function interpreter._filter(self, values, filter)

    -- check
    assert(self and values and filter)

    -- replace value
    local replace = function (value)

        -- replace the builtin variables
        return (value:gsub("%$%((.-)%)", function (variable) 

            -- check
            assert(variable)
                                        
            -- is upper?
            local isupper = false
            local c = string.char(variable:byte())
            if c >= 'A' and c <= 'Z' then isupper = true end

            -- filter it
            local result = filter(variable:lower())

            -- convert to upper?
            if isupper and result and type(result) == "string" then
                result = result:upper() 
            end

            -- ok?
            return result
        end))
    end

    -- done
    local results = {}
    if table.is_dictionary(values) then
        -- replace keyvalues
        for key, value in pairs(values) do
            results[replace(key)] = replace(value)
        end
    else
        for _, value in ipairs(utils.wrap(values)) do

            -- string?
            if type(value) == "string" then
                
                -- replace value
                value = replace(value)

            -- array?
            elseif table.is_array(value) then

                -- replace values
                local values = {}
                for _, v in ipairs(value) do
                    table.insert(values, replace(v))
                end
                value = values
            end

            -- append value
            table.insert(results, value)
        end
    end

    -- ok?
    return results
end

-- handle scope
function interpreter._handle(self, scope, remove_repeat, enable_filter, filter)

    -- check
    assert(scope)

    -- remove repeat values and unwrap it
    local results = {}
    for name, values in pairs(scope) do

        -- remove repeat first
        if remove_repeat and not table.is_dictionary(values) then
            values = utils.unique(values)
        end

        -- filter values
        if filter and enable_filter then
            values = self:_filter(values, filter)
        end

        -- unwrap it if be only one
        values = utils.unwrap(values)

        -- update it
        results[name] = values
    end

    -- ok?
    return results
end

-- make results
function interpreter._make(self, scope_kind, remove_repeat, enable_filter)

    -- check
    assert(self and self._PRIVATE)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes and scopes._ROOT)

    -- the filter
    local filter = self._PRIVATE._FILTER

    -- make results
    local results = {}
    if scope_kind then

        -- not this scope for kind?
        local scope_for_kind = scopes[scope_kind]
        if not scope_for_kind then
            return nil
        end

        -- the root scope
        local scope_root = scopes._ROOT[scope_kind]

        -- merge results
        for scope_name, scope in pairs(scope_for_kind) do

            -- add scope values
            local scope_values = {}
            for name, values in pairs(scope) do
                if not name:startswith("__override_") then
                    scope_values[name] = values
                end
            end

            -- merge root values
            if scope_root then
                for name, values in pairs(scope_root) do

                    -- merge values?
                    if not scope["__override_" .. name] then

                        -- merge or add it
                        if scope_values[name] ~= nil then
                            scope_values[name] = table.join(values, scope_values[name])
                        else
                            scope_values[name] = values
                        end
                    end
                end
            end

            -- add this scope
            results[scope_name] = self:_handle(scope_values, remove_repeat, enable_filter, filter)
        end

    else

        -- only uses the root scope kind
        results = self:_handle(scopes._ROOT["__rootkind"], remove_repeat, enable_filter, filter)

    end

    -- ok?
    return results
end

-- init interpreter
function interpreter.init()

    -- init an interpreter instance
    local self = {  _PUBLIC = {}
                ,   _PRIVATE = {    _SCOPES = {}
                                ,   _MTIMES = {}}}

    -- inherit the interfaces of interpreter
    for k, v in pairs(interpreter) do
        if type(v) == "function" then
            self[k] = v
        end
    end

    -- register the builtin interfaces
    self:api_register("add_subdirs", interpreter.api_builtin_add_subdirs)
    self:api_register("add_subfiles", interpreter.api_builtin_add_subfiles)

    -- register the builtin interfaces for lua
    self:api_register_builtin("print", print)
    self:api_register_builtin("pairs", pairs)
    self:api_register_builtin("ipairs", ipairs)
    self:api_register_builtin("format", string.format)
    self:api_register_builtin("printf", utils.printf)

    -- register the builtin modules for lua
    self:api_register_builtin("path", path)
    self:api_register_builtin("table", table)
    self:api_register_builtin("string", string)

    -- ok?
    return self
end

-- load results 
function interpreter.load(self, file, scope_kind, remove_repeat, enable_filter)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE and file)

    -- load the script
    local script, errors = loadfile(file)
    if not script then
        return nil, errors
    end

    -- clear first
    self:_clear()

    -- init the current file 
    self._PRIVATE._CURFILE = file

    -- init the root directory
    self._PRIVATE._ROOTDIR = self._PRIVATE._ROOTDIR or path.directory(file)
    assert(self._PRIVATE._ROOTDIR)

    -- init mtime for the current file
    self._PRIVATE._MTIMES[path.relative(file, self._PRIVATE._ROOTDIR)] = os.mtime(file)

    -- bind public scope
    setfenv(script, self._PUBLIC)

    -- done interpreter
    local ok, errors = xpcall(script, interpreter._traceback)
    if not ok then
        return nil, errors
    end

    -- make results
    return self:_make(scope_kind, remove_repeat, enable_filter)
end

-- get mtimes
function interpreter.mtimes(self)

    -- check
    assert(self and self._PRIVATE)

    -- get mtimes
    return self._PRIVATE._MTIMES
end

-- set filter
function interpreter.filter_set(self, filter)

    -- check
    assert(self and self._PRIVATE)
    assert(filter == nil or type(filter) == "function")

    -- set it
    self._PRIVATE._FILTER = filter
end

-- set root directory
function interpreter.rootdir_set(self, rootdir)

    -- check
    assert(self and self._PRIVATE and rootdir)

    -- set it
    self._PRIVATE._ROOTDIR = rootdir
end

-- register api 
function interpreter.api_register(self, name, func)

    -- check
    assert(self and self._PUBLIC)
    assert(name and func)

    -- register it
    self._PUBLIC[name] = function (...) return func(self, ...) end
end

-- register api for builtin
function interpreter.api_register_builtin(self, name, func)

    -- check
    assert(self and self._PUBLIC and func)

    -- register it
    self._PUBLIC[name] = func
end

-- register api for set_scope()
--
-- interp:api_register_set_scope("scope_kind1", "scope_kind2")
--
-- api:
--   set_$(scope_kind1)("scope_name1")
--       ...
--
--   set_$(scope_kind2)("scope_name1", "scope_name2")
--       ...
--   
-- result:
--
-- _PRIVATE
-- {
--      _SCOPES
--      {
--          scope_kind1
--          {  
--              "scope_name1"
--              {
--
--              }
--          }
--
--          scope_kind2
--          {  
--              "scope_name1"
--              {
--
--              }
--
--              "scope_name2" <-- _SCOPES._CURRENT
--              {
--
--              }
--          }
--      }
-- }
--
function interpreter.api_register_set_scope(self, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- check 
        if not scope_for_kind[scope_name] then
            utils.error("set_%s(\"%s\") failed, %s not found!", scope_kind, scope_name, scope_name)
            utils.error("please uses add_%s(\"%s\") first!", scope_kind, scope_name)
            utils.abort()
        end

        -- init scope for name
        scope_for_kind[scope_name] = scope_for_kind[scope_name] or {}

        -- save the current scope
        scopes._CURRENT = scope_for_kind[scope_name]

        -- update the current scope kind
        scopes._CURRENT_KIND = scope_kind

    end

    -- register implementation
    self:_api_register_xxx_scope("set", implementation, ...)
end

-- register api for add_scope()
function interpreter.api_register_add_scope(self, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- check 
        if scope_for_kind[scope_name] then
            utils.error("add_%s(\"%s\") failed, %s have been defined!", scope_kind, scope_name, scope_name)
            utils.error("please uses set_%s(\"%s\")!", scope_kind, scope_name)
            utils.abort()
        end

        -- init scope for name
        scope_for_kind[scope_name] = scope_for_kind[scope_name] or {}

        -- save the current scope
        scopes._CURRENT = scope_for_kind[scope_name]

        -- update the current scope kind
        scopes._CURRENT_KIND = scope_kind

    end

    -- register implementation
    self:_api_register_xxx_scope("add", implementation, ...)
end

-- register api for set_values
--
-- interp:api_register_set_values("scope_kind", "name1", "name2", ...)
--
-- api:
--   set_$(name1)("value1")
--   set_$(name2)("value1", "value2", ...)
--
-- result:
--
-- _PRIVATE
-- {
--      _SCOPES
--      {
--          _ROOT
--          {
--              scope_kind
--              {
--                  name2 = {"value3"}    
--              }
--          }
--
--          scope_kind
--          {  
--              "scope_name" <-- _SCOPES._CURRENT
--              {
--                  name1 = {"value1"}
--                  name2 = {"value1", "value2", ...}
--
--                  __override_name1 = true <- override
--              }
--          }
--      }
-- }
--
function interpreter.api_register_set_values(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update values?
        scope[name] = {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- register api for add_values
function interpreter.api_register_add_values(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append values?
        scope[name] = scope[name] or {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", prefix, implementation, ...)
end

-- register api for set_array
function interpreter.api_register_set_array(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update array?
        scope[name] = {}
        table.insert(scope[name], {...})

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- register api for add_array
function interpreter.api_register_add_array(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append array?
        scope[name] = scope[name] or {}
        table.insert(scope[name], {...})

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", prefix, implementation, ...)
end

-- register api for set_script
function interpreter.api_register_set_script(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- check
        if script == nil then
            utils.error("set_%s(\"%s\"): no script", scope, name)
            utils.abort()
        end
        if type(script) == "string" and not os.isfile(script) then
            utils.error("set_%s(\"%s\"): scriptfile(%s) not found!", scope, name, script)
            utils.abort()
        end

        -- update script?
        scope[name] = {}
        table.insert(scope[name], script)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- register api for set_keyvalues
function interpreter.api_register_set_keyvalues(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update keyvalues?
        scope[name] = {}
        table.insert(scope[name], {...})

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- register api for add_keyvalues
function interpreter.api_register_add_keyvalues(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append keyvalues?
        scope[name] = scope[name] or {}

        -- the values
        local values = {...}
        local count = #values

        -- check count
        if (count % 2) == 1 then
            utils.error("add_%s() values must be key-value pair!", name)
            utils.abort()
        end

        -- done
        local i = 0
        local keyvalues = scope[name]
        while i + 2 <= count do
            
            -- the key and value
            local key = values[i + 1]
            local val = values[i + 2]

            -- insert key and value
            keyvalues[key] = val

            -- next pair
            i = i + 2
        end

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", prefix, implementation, ...)
end

-- register api for set_pathes
function interpreter.api_register_set_pathes(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update values?
        scope[name] = {}
        table.join2(scope[name], self:_api_translate_pathes(...))

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- register api for add_pathes
function interpreter.api_register_add_pathes(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append values?
        scope[name] = scope[name] or {}
        table.join2(scope[name], self:_api_translate_pathes(...))

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", prefix, implementation, ...)
end

-- the builtin api: add_subdirs()
function interpreter.api_builtin_add_subdirs(self, ...)
    
    -- check
    assert(self)

    -- done
    return self:_api_builtin_add_subdirfiles(true, ...)
end

-- the builtin api: add_subfiles()
function interpreter.api_builtin_add_subfiles(self, ...)
 
    -- check
    assert(self)

    -- done
    return self:_api_builtin_add_subdirfiles(false, ...)
end

-- call api
function interpreter.api_call(self, apiname, ...)

    -- check
    assert(self and self._PUBLIC and apiname)

    -- get api function
    local apifunc = self._PUBLIC[apiname]
    if not apifunc then
        utils.error("call %s() failed, the api %s not found!", apiname)
        utils.abort() 
    end

    -- call api function
    return apifunc(...)
end

-- save the current scope
function interpreter.scope_save(self)

    -- check
    assert(self and self._PRIVATE)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes)

    -- the current scope
    local scope = {}
    scope._CURRENT      = scopes._CURRENT
    scope._CURRENT_KIND = scopes._CURRENT_KIND

    -- ok?
    return scope
end

-- restore the current scope
function interpreter.scope_restore(self, scope)

    -- check
    assert(self and self._PRIVATE and scope)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes)

    -- restore it
    scopes._CURRENT      = scope._CURRENT
    scopes._CURRENT_KIND = scope._CURRENT_KIND

end

-- return module: interpreter
return interpreter
