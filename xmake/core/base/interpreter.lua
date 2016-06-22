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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
local sandbox   = require("sandbox/sandbox")

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
        if not info then
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
function interpreter:_api_register_xxx_scope(scope_kind, action, apifunc, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(apifunc)

    -- done
    for _, apiname in ipairs({...}) do

        -- check
        assert(apiname)

        -- the full name
        local fullname = apiname
        if action ~= nil then
            fullname = action .. "_" .. apiname
        end

        -- register scope api
        self:api_register(scope_kind, fullname, function (self, ...) 
       
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
function interpreter:_api_register_xxx_values(scope_kind, action, apifunc, ...)

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
    self:_api_register_xxx_scope(scope_kind, action, implementation, ...)
end

-- translate api pathes 
function interpreter:_api_translate_pathes(...)

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
function interpreter:_api_builtin_add_subdirfiles(isdirs, ...)

    -- check
    assert(self and self._PRIVATE and self._PRIVATE._ROOTDIR and self._PRIVATE._MTIMES)

    -- the current file 
    local curfile = self._PRIVATE._CURFILE
    assert(curfile)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes)

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

                -- save the previous scope
                local scope_prev = scopes._CURRENT

                -- save the previous scope kind
                local scope_kind_prev = scopes._CURRENT_KIND

                -- clear the current scope, force to enter root scope
                scopes._CURRENT = nil

                -- done interpreter
                local ok, errors = xpcall(script, interpreter._traceback)
                if not ok then
                    os.raise(errors)
                end

                -- restore the previous scope kind
                scopes._CURRENT_KIND = scope_kind_prev

                -- restore the previous scope
                scopes._CURRENT = scope_prev

                -- get mtime of the file
                self._PRIVATE._MTIMES[path.relative(file, self._PRIVATE._ROOTDIR)] = os.mtime(file)
            else
                os.raise(errors)
            end
        end
    end

    -- restore the current file 
    self._PRIVATE._CURFILE = curfile
end

-- get api function within scope
function interpreter:_api_within_scope(scope_kind, apiname)

    -- the private
    local priv = self._PRIVATE
    assert(priv)

    -- the scopes
    local scopes = priv._SCOPES
    assert(scopes)

    -- done
    if scope_kind and priv._APIS then

        -- get api function
        local api_scope = priv._APIS[scope_kind]
        if api_scope then
            return api_scope[apiname]
        end
    end
end

-- clear results
function interpreter:_clear()

    -- check
    assert(self and self._PRIVATE)

    -- clear it
    self._PRIVATE._SCOPES = {}
    self._PRIVATE._MTIMES = {}
end

-- filter values
function interpreter:_filter(values)

    -- check
    assert(self and values)

    -- return values directly if no filter
    local filter = self._PRIVATE._FILTER
    if filter == nil then
        return values
    end

    -- done
    local results = {}
    if table.is_dictionary(values) then
        -- filter keyvalues
        for key, value in pairs(values) do
            if type(value) == "string" then
                results[filter:handle(key)] = filter:handle(value)
            else
                results[filter:handle(key)] = value
            end
        end
    else
        for _, value in ipairs(table.wrap(values)) do

            -- string?
            if type(value) == "string" then
                
                -- filter value
                value = filter:handle(value)

            -- array?
            elseif table.is_array(value) then

                -- replace values
                local values = {}
                for _, v in ipairs(value) do
                    if type(v) == "string" then
                        table.insert(values, filter:handle(v))
                    else
                        table.insert(values, v)
                    end
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
function interpreter:_handle(scope, remove_repeat, enable_filter)

    -- check
    assert(scope)

    -- remove repeat values and unwrap it
    local results = {}
    for name, values in pairs(scope) do

        -- remove repeat first
        if remove_repeat and not table.is_dictionary(values) then
            values = table.unique(values)
        end

        -- filter values
        if enable_filter then
            values = self:_filter(values)
        end

        -- unwrap it if be only one
        values = table.unwrap(values)

        -- update it
        results[name] = values
    end

    -- ok?
    return results
end

-- make results
function interpreter:_make(scope_kind, remove_repeat, enable_filter)

    -- check
    assert(self and self._PRIVATE)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES

    -- empty scope?
    if not scopes or not scopes._ROOT then
        return nil, string.format("the scope %s() is empty!", scope_kind)
    end

    -- make results
    local results = {}
    if scope_kind then

        -- not this scope for kind?
        local scope_for_kind = scopes[scope_kind]
        if not scope_for_kind then
            return {}
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
            results[scope_name] = self:_handle(scope_values, remove_repeat, enable_filter)
        end

    else

        -- only uses the root scope kind
        results = self:_handle(scopes._ROOT["__rootkind"], remove_repeat, enable_filter)

    end

    -- ok?
    return results
end

-- new an interpreter instance
function interpreter.new()

    -- init an interpreter instance
    local instance = {  _PUBLIC = {}
                    ,   _PRIVATE = {    _SCOPES = {}
                                    ,   _MTIMES = {}}}

    -- inherit the interfaces of interpreter
    table.inherit2(instance, interpreter)

    -- dispatch the api calling for scope
    setmetatable(instance._PUBLIC, {    __index = function (tbl, key)

                                            -- get the scope kind
                                            local priv = instance._PRIVATE
                                            local scope_kind = priv._SCOPES._CURRENT_KIND or priv._ROOTSCOPE

                                            -- get the api function from the given scope
                                            return instance:_api_within_scope(scope_kind, key)
                                    end}) 

    -- register the builtin interfaces
    instance:api_register(nil, "add_subdirs", interpreter.api_builtin_add_subdirs)
    instance:api_register(nil, "add_subfiles", interpreter.api_builtin_add_subfiles)

    -- register the builtin interfaces for lua
    instance:api_register_builtin("print", print)
    instance:api_register_builtin("pairs", pairs)
    instance:api_register_builtin("ipairs", ipairs)
    instance:api_register_builtin("format", string.format)
    instance:api_register_builtin("printf", utils.printf)

    -- register the builtin modules for lua
    instance:api_register_builtin("path", path)
    instance:api_register_builtin("table", table)
    instance:api_register_builtin("string", string)

    -- ok?
    return instance
end

-- load results 
function interpreter:load(file, scope_kind, remove_repeat, enable_filter)

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
    self._PRIVATE._ROOTDIR = path.directory(file)
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
    local ok, results = xpcall(interpreter._make, interpreter._traceback, self, scope_kind, remove_repeat, enable_filter)
    if not ok then
        return nil, results 
    end

    -- ok
    return results
end

-- get mtimes
function interpreter:mtimes()

    -- check
    assert(self and self._PRIVATE)

    -- get mtimes
    return self._PRIVATE._MTIMES
end

-- get filter
function interpreter:filter()

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._FILTER
end

-- set filter
function interpreter:filter_set(filter)

    -- check
    assert(self and self._PRIVATE)

    -- set it
    self._PRIVATE._FILTER = filter
end

-- get root directory
function interpreter:rootdir()

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._ROOTDIR
end

-- set root directory
function interpreter:rootdir_set(rootdir)

    -- check
    assert(self and self._PRIVATE and rootdir)

    -- set it
    self._PRIVATE._ROOTDIR = rootdir
end

-- set root scope kind
--
-- the root api will affect these scopes
--
function interpreter:rootscope_set(scope_kind)

    -- check
    assert(self and self._PRIVATE)

    -- set it
    self._PRIVATE._ROOTSCOPE = scope_kind
end

-- register api 
--
-- interp:api_register(nil, "apiroot", function () end)
-- interp:api_register("scope_kind", "apiname", function () end)
--
-- result:
--
-- _PUBLIC 
-- {
--      apiroot = function () end
-- }
--
-- _PRIVATE
-- {
--      _APIS
--      {
--          scope_kind
--          {  
--              apiname = function () end
--          }
--      }
-- }
--
function interpreter:api_register(scope_kind, name, func)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(name and func)

    -- register api to the given scope kind 
    if scope_kind and scope_kind ~= "__rootkind" then

        -- get apis
        self._PRIVATE._APIS = self._PRIVATE._APIS or {}
        local apis = self._PRIVATE._APIS

        -- get scope
        apis[scope_kind] = apis[scope_kind] or {}
        local scope = apis[scope_kind]

        -- register api
        scope[name] = function (...) return func(self, ...) end
    else
        -- register api to the root scope
        self._PUBLIC[name] = function (...) return func(self, ...) end
    end
end

-- register api for builtin
function interpreter:api_register_builtin(name, func)

    -- check
    assert(self and self._PUBLIC and func)

    -- register it
    self._PUBLIC[name] = func
end

-- register api for scope()
--
-- interp:api_register_scope("scope_kind1", "scope_kind2")
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
function interpreter:api_register_scope(...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- enter the given scope
        if scope_name ~= nil then

            -- init scope for name
            scope_for_kind[scope_name] = scope_for_kind[scope_name] or {}

            -- save the current scope
            scopes._CURRENT = scope_for_kind[scope_name]
        else

            -- enter root scope
            scopes._CURRENT = nil
        end

        -- update the current scope kind
        scopes._CURRENT_KIND = scope_kind
    end

    -- register implementation
    self:_api_register_xxx_scope(nil, nil, implementation, ...)
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
function interpreter:api_register_set_values(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update values?
        scope[name] = {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_values
function interpreter:api_register_add_values(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append values?
        scope[name] = scope[name] or {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- register api for set_array
function interpreter:api_register_set_array(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update array?
        scope[name] = {}
        table.insert(scope[name], {...})

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_array
function interpreter:api_register_add_array(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append array?
        scope[name] = scope[name] or {}
        table.insert(scope[name], {...})

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- register api for on_script
function interpreter:api_register_on_script(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, self:filter(), self:rootdir())
        if not instance then
            os.raise("on_%s(): %s", name, errors)
        end

        -- update script?
        scope[name] = instance:script()
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "on", implementation, ...)
end

-- register api for before_script
function interpreter:api_register_before_script(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, self:filter(), self:rootdir())
        if not instance then
            os.raise("before_%s(): %s", name, errors)
        end

        -- update script?
        scope[name .. "_before"] = instance:script()
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "before", implementation, ...)
end

-- register api for after_script
function interpreter:api_register_after_script(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, self:filter(), self:rootdir())
        if not instance then
            os.raise("after_%s(): %s", name, errors)
        end

        -- update script?
        scope[name .. "_after"] = instance:script()
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "after", implementation, ...)
end

-- register api for set_keyvalues
function interpreter:api_register_set_keyvalues(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update keyvalues?
        scope[name] = {}
        table.insert(scope[name], {...})
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_keyvalues
function interpreter:api_register_add_keyvalues(scope_kind, ...)

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
            os.raise("add_%s() values must be key-value pair!", name)
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
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- register api for set_pathes
function interpreter:api_register_set_pathes(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- update values?
        scope[name] = {}
        table.join2(scope[name], self:_api_translate_pathes(...))

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_pathes
function interpreter:api_register_add_pathes(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- append values?
        scope[name] = scope[name] or {}
        table.join2(scope[name], self:_api_translate_pathes(...))

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- the builtin api: add_subdirs()
function interpreter:api_builtin_add_subdirs(...)
    
    -- check
    assert(self)

    -- done
    return self:_api_builtin_add_subdirfiles(true, ...)
end

-- the builtin api: add_subfiles()
function interpreter:api_builtin_add_subfiles(...)
 
    -- check
    assert(self)

    -- done
    return self:_api_builtin_add_subdirfiles(false, ...)
end

-- call api
function interpreter:api_call(apiname, ...)

    -- check
    assert(self and self._PUBLIC and apiname)

    -- get api function
    local apifunc = self._PUBLIC[apiname]
    if not apifunc then
        os.raise("call %s() failed, this api not found!", apiname)
    end

    -- call api function
    return apifunc(...)
end

-- save the current scope
function interpreter:scope_save()

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
function interpreter:scope_restore(scope)

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
