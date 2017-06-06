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

    -- not verbose?
    if errors then
        local _, pos = errors:find("[nobacktrace]: ", 1, true)
        if pos then
            return errors:sub(pos + 1)
        end
    end

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

-- merge the current root values to the previous scope
function interpreter._merge_root_scope(root, root_prev, override)

    -- merge it
    root_prev = root_prev or {}
    for scope_kind_and_name, _ in pairs(root or {}) do
        
        -- is scope_kind.scope_name?
        scope_kind_and_name = scope_kind_and_name:split('%.')
        if #scope_kind_and_name == 2 then
            local scope_kind = scope_kind_and_name[1] 
            local scope_name = scope_kind_and_name[2]
            local scope_values = root_prev[scope_kind .. "." .. scope_name] or {}
            local scope_root = root[scope_kind .. "." .. scope_name] or {}
            for name, values in pairs(scope_root) do
                if not name:startswith("__") then
                    if scope_root["__override_" .. name] then
                        if override or scope_values[name] == nil then
                            scope_values[name] = values
                        end
                    else
                        scope_values[name] = table.join(values, scope_values[name] or {})
                    end
                end
            end
            root_prev[scope_kind .. "." .. scope_name] = scope_values
        end
    end

    -- ok?
    return root_prev
end

-- fetch the root values to the child values in root scope
-- and we will only use the child values if be override mode 
function interpreter._fetch_root_scope(root)

    -- fetch it
    for scope_kind_and_name, _ in pairs(root or {}) do
        
        -- is scope_kind.scope_name?
        scope_kind_and_name = scope_kind_and_name:split('%.')
        if #scope_kind_and_name == 2 then
            local scope_kind = scope_kind_and_name[1] 
            local scope_name = scope_kind_and_name[2]
            local scope_values = root[scope_kind .. "." .. scope_name] or {}
            local scope_root = root[scope_kind] or {}
            for name, values in pairs(scope_root) do
                if not name:startswith("__") then
                    if scope_root["__override_" .. name] then
                        if scope_values[name] == nil then
                            scope_values[name] = values
                        end
                    else
                        scope_values[name] = table.join(values, scope_values[name] or {})
                    end
                end
            end
            root[scope_kind .. "." .. scope_name] = scope_values
        end
    end
end

-- register scope end: scopename_end()
function interpreter:_api_register_scope_end(...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- done
    for _, apiname in ipairs({...}) do

        -- check
        assert(apiname)

        -- register scope api
        self:api_register(nil, apiname .. "_end", function (self, ...) 
       
            -- check
            assert(self and self._PRIVATE and apiname)

            -- the scopes
            local scopes = self._PRIVATE._SCOPES
            assert(scopes)

            -- enter root scope
            scopes._CURRENT = nil

            -- clear scope kind
            scopes._CURRENT_KIND = nil
        end)
    end
end

-- register scope api: xxx_apiname()
function interpreter:_api_register_scope_api(scope_kind, action, apifunc, ...)

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

        -- set values? mark as "override"
        if apiname and action ~= "add" then
            scope["__override_" .. apiname] = true
        end

        -- call function
        return apifunc(self, scope, apiname, ...) 
    end

    -- register implementation
    self:_api_register_scope_api(scope_kind, action, implementation, ...)
end

-- register api for xxx_script
function interpreter:_api_register_xxx_script(scope_kind, action, ...)

    -- define implementation
    local implementation = function (self, scope, name, arg1, arg2)

        -- patch action to name
        if action ~= "on" then
            name = name .. "_" .. action
        end

        -- on_xxx(pattern, script)?
        if arg1 and arg2 then

            -- get pattern
            local pattern = arg1
            assert(type(pattern) == "string")

            -- get script
            local script, errors = self:_script(arg2)
            if not script then
                os.raise("%s_%s(%s, %s): %s", action, name, tostring(arg1), tostring(arg2), errors)
            end

            -- convert pattern to a lua pattern ('*' => '.*')
            pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
            pattern = pattern:gsub("%*", "\001")
            pattern = pattern:gsub("\001", ".*")

            -- save script
            local scripts = scope[name] or {}
            if type(scripts) == "table" then
                scripts[pattern] = script
            elseif type(scripts) == "function" then
                scripts = {__generic__ = scripts}
                scripts[pattern] = script
            end
            scope[name] = scripts

        -- on_xxx(script)?
        elseif arg1 then

            -- get script
            local script, errors = self:_script(arg1)
            if not script then
                os.raise("%s_%s(%s): %s", action, name, tostring(arg1), errors)
            end

            -- save script
            local scripts = scope[name]
            if type(scripts) == "table" then
                scripts["__generic__"] = script
            else
                scripts = script
            end
            scope[name] = scripts
        end
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, action, implementation, ...)
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
    local subpathes = table.join(...)

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
                file = path.absolute(file)
            end

            -- update the current file
            self._PRIVATE._CURFILE = file

            -- load the file script
            local script, errors = loadfile(file)
            if script then

                -- bind public scope
                setfenv(script, self._PUBLIC)

                -- save the previous root scope
                local root_prev = scopes._ROOT

                -- save the previous scope
                local scope_prev = scopes._CURRENT

                -- save the previous scope kind
                local scope_kind_prev = scopes._CURRENT_KIND

                -- clear the current root scope 
                scopes._ROOT = nil

                -- clear the current scope, force to enter root scope
                scopes._CURRENT = nil

                -- save the current directory
                local olddir = os.curdir()

                -- enter the script directory
                os.cd(path.directory(file))

                -- done interpreter
                local ok, errors = xpcall(script, interpreter._traceback)
                if not ok then
                    os.raise(errors)
                end

                -- leave the script directory
                os.cd(olddir)

                -- restore the previous scope kind
                scopes._CURRENT_KIND = scope_kind_prev

                -- restore the previous scope
                scopes._CURRENT = scope_prev

                -- fetch the root values in root scopes first
                interpreter._fetch_root_scope(scopes._ROOT)

                -- restore the previous root scope and merge current root scope
                -- it will override the previous values if the current values are override mode 
                -- so we priority use the values in subdirs scope
                scopes._ROOT = interpreter._merge_root_scope(scopes._ROOT, root_prev, true)

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

    -- get scope api
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

        -- fetch the root values in root scope first 
        interpreter._fetch_root_scope(scopes._ROOT)

        -- merge results
        for scope_name, scope in pairs(scope_for_kind) do

            -- add scope values
            local scope_values = {}
            for name, values in pairs(scope) do
                if not name:startswith("__override_") then
                    scope_values[name] = values
                end
            end

            -- merge root values with the given scope name
            local scope_root = scopes._ROOT[scope_kind .. "." .. scope_name]
            if scope_root then
                for name, values in pairs(scope_root) do
                    if not scope["__override_" .. name] then
                        scope_values[name] = table.join(values, scope_values[name] or {})
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

-- load script
function interpreter:_script(script)

    -- this script is module name? import it first
    if type(script) == "string" then
    
        -- import module as script
        local modulename = script
        script = function (...)
       
            -- import it
            _g._module = _g._module or import(modulename, {anonymous = true})
            return _g._module(...)
        end
    end

    -- make sandbox instance with the given script
    local instance, errors = sandbox.new(script, self:filter(), self:scriptdir())
    if not instance then
        return nil, errors
    end

    -- get sandbox script
    return instance:script()
end

-- new an interpreter instance
function interpreter.new()

    -- init an interpreter instance
    local instance = {  _PUBLIC = {}
                    ,   _PRIVATE = {    _SCOPES = {}
                                    ,   _MTIMES = {}
                                    ,   _FILTER = require("base/filter").new()}}

    -- inherit the interfaces of interpreter
    table.inherit2(instance, interpreter)

    -- dispatch the api calling for scope
    setmetatable(instance._PUBLIC, {    __index = function (tbl, key)

                                            -- get the scope kind
                                            local priv          = instance._PRIVATE
                                            local current_kind  = priv._SCOPES._CURRENT_KIND
                                            local scope_kind    = current_kind or priv._ROOTSCOPE

                                            -- get the api function from the given scope
                                            local apifunc = instance:_api_within_scope(scope_kind, key)

                                            -- get the api function from the root scope
                                            if not apifunc and priv._ROOTAPIS then
                                                apifunc = priv._ROOTAPIS[key]
                                            end

                                            -- ok?
                                            return apifunc
                                    end}) 

    -- register the builtin interfaces
    instance:api_register(nil, "add_subdirs", interpreter.api_builtin_add_subdirs)
    instance:api_register(nil, "add_subfiles", interpreter.api_builtin_add_subfiles)
    instance:api_register(nil, "set_xmakever", interpreter.api_builtin_set_xmakever)

    -- load builtin module files
    local builtin_module_files = os.match(path.join(xmake._CORE_DIR, "sandbox/modules/interpreter/*.lua"))
    if builtin_module_files then
        for _, builtin_module_file in ipairs(builtin_module_files) do

            -- the module name
            local module_name = path.basename(builtin_module_file)
            assert(module_name)

            -- load script
            local script, errors = loadfile(builtin_module_file)
            if script then

                -- load module
                local ok, results = xpcall(script, debug.traceback)
                if not ok then
                    os.raise(results)
                end

                -- register module
                instance:api_register_builtin(module_name, results)
            else
                -- error
                os.raise(errors)
            end
        end
    end

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

-- get script directory
function interpreter:scriptdir()

    -- check
    assert(self and self._PRIVATE and self._PRIVATE._CURFILE)

    -- get it
    return path.directory(self._PRIVATE._CURFILE)
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
-- _PRIVATE
-- {
--      _APIS
--      {
--          scope_kind
--          {  
--              apiname = function () end
--          }
--      }
--      
--      _ROOTAPIS
--      {
--          apiroot = function () end
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

        -- get root apis
        self._PRIVATE._ROOTAPIS = self._PRIVATE._ROOTAPIS or {}
        local apis = self._PRIVATE._ROOTAPIS

        -- register api to the root scope
        apis[name] = function (...) return func(self, ...) end
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
--                   __scriptdir = "" (the directory of xmake.lua)
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

        -- is dictionary mode?
        --
        -- .e.g 
        -- target
        -- {
        --    name = "tbox"
        --    kind = "static",
        --    files =
        --    {
        --        "src/*.c",
        --        "*.cpp"
        --    }
        --}
        local scope_info = nil
        if type(scope_name) == "table" and scope_name["name"] ~= nil then

            -- get the scope info
            scope_info = scope_name

            -- get the scope name from the dictionary
            scope_name = scope_name["name"]
        end


        -- enter the given scope
        if scope_name ~= nil then

            -- init scope for name
            local scope = scope_for_kind[scope_name] or {}
            scope_for_kind[scope_name] = scope

            -- save the current scope
            scopes._CURRENT = scope

            -- save script directory of scope when enter this scope first
            scope.__scriptdir = scope.__scriptdir or self:scriptdir()
        else

            -- enter root scope
            scopes._CURRENT = nil
        end

        -- update the current scope kind
        scopes._CURRENT_KIND = scope_kind

        -- init scope_kind.scope_name for the current root scope
        scopes._ROOT = scopes._ROOT or {}
        if scope_name ~= nil then
            scopes._ROOT[scope_kind .. "." .. scope_name] = {}
        end

        -- translate scope info 
        if scope_info then
            scope_info["name"] = nil
            for name, values in pairs(scope_info) do
                local apifunc = self:api_func("set_" .. name) or self:api_func("add_" .. name) or self:api_func("on_" .. name) or self:api_func(name)
                if apifunc then
                    apifunc(values)
                else
                    os.raise("unknown %s for %s(\"%s\")", name, scope_kind, scope_name)
                end
            end
        end
    end

    -- register implementation to the root scope
    self:_api_register_scope_api(nil, nil, implementation, ...)

    -- register scope end
    self:_api_register_scope_end(...)
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

-- register api for set_module 
function interpreter:api_register_set_module(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, modulename)

        -- is module name?
        if type(modulename) ~= "string" then
            os.raise("set_%s(): invalid module name!", name)
        end
        
        -- import module as script
        local script, errors = loadstring(string.format("import(\"%s\", {inherit = true})", modulename))
        if not script then
            os.raise("set_%s(): %s", name, errors)
        end

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, self:filter(), self:scriptdir())
        if not instance then
            os.raise("set_%s(): %s", name, errors)
        end

        -- import the module
        local module, errors = instance:import()
        if not module then
            os.raise("set_%s(): %s", name, errors)
        end

        -- init the module
        if module.init then
            module.init()
        end
    
        -- save module
        scope[name] = module
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for on_script
function interpreter:api_register_on_script(scope_kind, ...)

    -- register implementation
    self:_api_register_xxx_script(scope_kind, "on", ...)
end

-- register api for before_script
function interpreter:api_register_before_script(scope_kind, ...)

    -- register implementation
    self:_api_register_xxx_script(scope_kind, "before", ...)
end

-- register api for after_script
function interpreter:api_register_after_script(scope_kind, ...)

    -- register implementation
    self:_api_register_xxx_script(scope_kind, "after", ...)
end

-- register api for set_dictionary
function interpreter:api_register_set_dictionary(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, dict_or_key, value)

        -- check
        if type(dict_or_key) == "table" then
            scope[name] = dict_or_key
        elseif type(dict_or_key) == "string" and value ~= nil then
            scope[name] = {dict_or_key = value}
        else
            -- error
            os.raise("set_%s(%s): invalid value type!", name, type(dict))
        end
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_dictionary
function interpreter:api_register_add_dictionary(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, dict_or_key, value)

        -- check
        scope[name] = scope[name] or {}
        if type(dict_or_key) == "table" then
            table.join2(scope[name], dict_or_key)
        elseif type(dict_or_key) == "string" and value ~= nil then
            scope[name][dict_or_key] = value
        else
            -- error
            os.raise("add_%s(%s): invalid value type!", name, type(dict))
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

-- define apis 
--
-- @code
--  interp:api_define 
--  {
--      values = 
--      {
--          -- target.add_xxx
--          "target.add_links"
--      ,   "target.add_gcflags"
--      ,   "target.add_ldflags"
--      ,   "target.add_arflags"
--      ,   "target.add_shflags"
--
--          -- option.add_xxx
--      ,   "option.add_links"
--      ,   "option.add_gcflags"
--      ,   "option.add_ldflags"
--      ,   "option.add_arflags"
--      ,   "option.add_shflags"
--
--          -- is_xxx
--      ,   {"is_os", function (interp, ...) end}
--      }
--  ,   pathes = 
--      {
--          -- target.add_xxx
--          "target.add_linkdirs"
--          -- option.add_xxx
--      ,   "option.add_linkdirs"
--      }
--  }
-- @endcode
--
function interpreter:api_define(apis)
 
    -- register language apis
    local scopes = {}
    for apitype, apifuncs in pairs(apis) do
        for _, apifunc in ipairs(apifuncs) do

            -- is {"apifunc", apiscipt}?
            local apiscript = nil
            if type(apifunc) == "table" then

                -- check
                assert(#apifunc == 2 and type(apifunc[2]) == "function")

                -- get function and script
                apiscript   = apifunc[2]
                apifunc     = apifunc[1]
            end

            -- get api function 
            local apiscope = nil
            local funcname = nil
            apifunc = apifunc:split('.')
            assert(apifunc)
            if #apifunc == 2 then
                apiscope = apifunc[1]
                funcname = apifunc[2]
            else
                funcname = apifunc[1]
            end
            assert(funcname)

            -- register api script directly
            if apiscript ~= nil then
                self:api_register(apiscope, funcname, apiscript)
            else

                -- get function prefix
                local prefix = nil
                for _, name in ipairs({"set", "add", "on", "before", "after"}) do
                    if funcname:startswith(name .. "_") then
                        prefix = name
                        break
                    end
                end
                assert(prefix)

                -- get function name
                funcname = funcname:sub(#prefix + 2)

                -- get register
                local register = self[string.format("api_register_%s_%s", prefix, apitype)]
                if not register then
                    os.raise("interp:api_register_%s_%s() is unknown!", prefix, apitype)
                end

                -- register scope first 
                if apiscope ~= nil and not scopes[apiscope] then
                    self:api_register_scope(apiscope)
                    scopes[apiscope] = true
                end
            
                -- register api
                register(self, apiscope, funcname)
            end
        end
    end
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

-- the builtin api: set_xmakever()
function interpreter:api_builtin_set_xmakever(minver)

    -- no version
    if not minver then
        os.raise("[nobacktrace]: set_xmakever(): no version!")
    end

    -- parse minimum version
    local minvers = minver:split('.')
    if not minvers or #minvers ~= 3 then
        os.raise("[nobacktrace]: set_xmakever(\"%s\"): invalid version format!", minver)
    end

    -- make minimum numerical version
    local minvers_num = minvers[1] * 100 + minvers[2] * 10 + minvers[3]

    -- parse current version
    local curvers = xmake._VERSION_SHORT:split('.')

    -- make current numerical version
    local curvers_num = curvers[1] * 100 + curvers[2] * 10 + curvers[3]

    -- check version
    if curvers_num < minvers_num then
        os.raise("[nobacktrace]: xmake v%s < v%s, please upgrade xmake!", xmake._VERSION_SHORT, minver)
    end
end

-- get api function
function interpreter:api_func(apiname)

    -- check
    assert(self and self._PUBLIC and apiname)

    -- get api function
    return self._PUBLIC[apiname]
end

-- call api
function interpreter:api_call(apiname, ...)

    -- check
    assert(self and apiname)

    -- get api function
    local apifunc = self:api_func(apiname)
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
