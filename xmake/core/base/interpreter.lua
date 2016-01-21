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
            apifunc(self, scopes, apiname, ...) 
        end)
    end
end

-- register api: xxx_values()
function interpreter._api_register_xxx_values(self, scope_kind, action, prefix, apifunc, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(action and scope_kind and apifunc)

    -- define implementation
    local implementation = function (self, scopes, apiname, ...)

        -- init root scopes
        scopes._ROOT = scopes._ROOT or {}

        -- init current root scope
        local root = scopes._ROOT[scope_kind] or {}
        scopes._ROOT[scope_kind] = root

        -- the current scope
        local scope = scopes._CURRENT or root
        assert(scope)

        -- enter subscope and set values? override it
        if scopes._CURRENT and apiname and action == "set" then
            scope["_" .. apiname] = true
        end

        -- call function
        apifunc(self, scope, apiname, ...) 
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
            local script = loadfile(file)
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

    -- done
    local results = {}
    for _, value in ipairs(utils.wrap(values)) do

        -- only filter string value
        if type(value) == "string" then

            -- replace the builtin variables
            value = value:gsub("%$%((.-)%)", function (variable) 

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
            end)
        end

        -- append value
        table.insert(results, value)
    end

    -- ok?
    return results
end

-- make results
function interpreter._make(self, scope_kind, remove_repeat, filter)

    -- check
    assert(self and self._PRIVATE and scope_kind)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes and scopes._ROOT)

    -- the scope for kind
    local scope_for_kind = scopes[scope_kind]
    if not scope_for_kind then
        return nil, string.format("this scope kind: %s not found!", scope_kind)
    end

    -- the root scope
    local scope_root = scopes._ROOT[scope_kind]

    -- make results
    local results = {}
    for scope_name, scope in pairs(scope_for_kind) do

        -- add scope values and merge root values
        local scope_values = {}
        for name, values in pairs(scope) do
            if not name:startswith("_") then

                -- override values?
                if scope["_" .. name] then

                    -- override it
                    scope_values[name] = values

                -- merge root values?
                elseif scope_root then
                    
                    -- the root values
                    local root_values = scope_root[name]
                    if root_values ~= nil then
                        scope_values[name] = table.join(root_values, values)
                    else
                        scope_values[name] = values
                    end
                end
            end
        end

        -- remove repeat values and unwrap it
        local result_values = {}
        for name, values in pairs(scope_values) do

            -- remove repeat first
            if remove_repeat then
                values = utils.unique(values)
            end

            -- filter values
            if filter and type(filter) == "function" then
                values = self:_filter(values, filter)
            end

            -- unwrap it if be only one
            values = utils.unwrap(values)

            -- update it
            result_values[name] = values
        end

        -- add this scope
        results[scope_name] = result_values
    end

    -- ok?
    return results
end

-- init interpreter
function interpreter.init(rootdir)

    -- check
    assert(rootdir)

    -- init an interpreter instance
    local interp = {    _PUBLIC = {}
                    ,   _PRIVATE = {    _SCOPES = {}
                                    ,   _MTIMES = {}
                                    ,   _ROOTDIR = rootdir}}

    -- inherit the interfaces of interpreter
    for k, v in pairs(interpreter) do
        if type(v) == "function" then
            interp[k] = v
        end
    end

    -- register the builtin interfaces
    interp:api_register("add_subdirs", interpreter.api_builtin_add_subdirs)
    interp:api_register("add_subfiles", interpreter.api_builtin_add_subfiles)

    -- ok?
    return interp
end

-- load results 
function interpreter.load(self, file, scope_kind, remove_repeat, filter)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE and file and scope_kind)

    -- load the script
    local script = loadfile(file)
    if not script then
        return nil, string.format("load %s failed!", file)
    end

    -- clear first
    self:_clear()

    -- init the current file 
    self._PRIVATE._CURFILE = file

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
    return self:_make(scope_kind, remove_repeat, filter)
end

-- get mtimes
function interpreter.mtimes(self)

    -- check
    assert(self and self._PRIVATE)

    -- get mtimes
    return self._PRIVATE._MTIMES
end

-- register api 
function interpreter.api_register(self, name, func)

    -- check
    assert(self and self._PUBLIC)
    assert(name and func)

    -- register it
    self._PUBLIC[name] = function (...) func(self, ...) end
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

        -- check 
        if not scopes[scope_kind] then
            utils.error("set_%s(\"%s\") failed, %s not found!", scope_kind, scope_name, scope_name)
            utils.error("please uses add_%s(\"%s\") first!", scope_name)
            utils.abort()
        end

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- init scope for name
        scope_for_kind[scope_name] = scope_for_kind[scope_name] or {}

        -- save the current scope
        scopes._CURRENT = scope_for_kind[scope_name]

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

        -- check 
       if scopes[scope_kind] then
            utils.error("add_%s(\"%s\") failed, %s have been defined!", scope_name, scope_name)
            utils.error("please uses set_%s(\"%s\")!", scope_name)
            utils.abort()
        end

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- init scope for name
        scope_for_kind[scope_name] = scope_for_kind[scope_name] or {}

        -- save the current scope
        scopes._CURRENT = scope_for_kind[scope_name]

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
--                  _name1 = true <- override
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
    self:_api_builtin_add_subdirfiles(true, ...)
end

-- the builtin api: add_subfiles()
function interpreter.api_builtin_add_subfiles(self, ...)
 
    -- check
    assert(self)

    -- done
    self:_api_builtin_add_subdirfiles(false, ...)
end

-- return module: interpreter
return interpreter
