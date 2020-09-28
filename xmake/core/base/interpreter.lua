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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
local scopeinfo = require("base/scopeinfo")
local sandbox   = require("sandbox/sandbox")

-- traceback
function interpreter._traceback(errors)

    -- disable backtrace?
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
        -- only merge sub-scope for each kind("target@@xxxx") or __rootkind
        -- we need ignore the sub-root scope e.g. target{} after fetching root scope
        --
        if scope_kind_and_name:find("@@", 1, true) or scope_kind_and_name == "__rootkind" then
            local scope_values = root_prev[scope_kind_and_name] or {}
            local scope_root   = root[scope_kind_and_name] or {}
            for name, values in pairs(scope_root) do
                if not name:startswith("__override_") then
                    if scope_root["__override_" .. name] then
                        if override or scope_values[name] == nil then
                            scope_values[name] = values
                        end
                    else
                        scope_values[name] = table.join(values, scope_values[name] or {})
                    end
                end
            end
            root_prev[scope_kind_and_name] = scope_values
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

        -- is scope_kind@@scope_name?
        scope_kind_and_name = scope_kind_and_name:split("@@", {plain = true})
        if #scope_kind_and_name == 2 then
            local scope_kind = scope_kind_and_name[1]
            local scope_name = scope_kind_and_name[2]
            local scope_values = root[scope_kind .. "@@" .. scope_name] or {}
            local scope_root = root[scope_kind] or {}
            for name, values in pairs(scope_root) do
                if not name:startswith("__override_") then
                    if scope_root["__override_" .. name] then
                        if scope_values[name] == nil then
                            scope_values[name] = values
                            scope_values["__override_" .. name] = true
                        end
                    else
                        scope_values[name] = table.join(values, scope_values[name] or {})
                    end
                end
            end
            root[scope_kind .. "@@" .. scope_name] = scope_values
        end
    end
end

-- save api source info, e.g. call api() in sourcefile:linenumber
function interpreter:_save_sourceinfo_to_scope(scope, apiname, values)

    -- save api source info, e.g. call api() in sourcefile:linenumber
    local sourceinfo = debug.getinfo(3, "Sl")
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
            os.raise("%s() cannot be called in %s(), please move it to the %s scope!", apiname, scopes._CURRENT_KIND, scope_kind == "__rootkind" and "root" or scope_kind)
            scopes._CURRENT = nil
        end

        -- the current scope
        local scope = scopes._CURRENT or root
        assert(scope)

        -- set values (set, on, before, after ...)? mark as "override"
        if apiname and (action ~= "add" and action ~= "del") then
            scope["__override_" .. apiname] = true
        end

        -- save api source info, e.g. call api() in sourcefile:linenumber
        self:_save_sourceinfo_to_scope(scope, apiname, {...})

        -- call function
        return apifunc(self, scope, apiname, ...)
    end

    -- register implementation
    self:_api_register_scope_api(scope_kind, action, implementation, ...)
end

-- register api for xxx_script
function interpreter:_api_register_xxx_script(scope_kind, action, ...)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- patch action to name
        if action ~= "on" then
            name = name .. "_" .. action
        end

        -- get arguments, pattern1, pattern2, ..., script function or name
        local args = {...}

        -- get and save extra config
        local extra_config = args[#args]
        if table.is_dictionary(extra_config) then
            table.remove(args)
            scope["__extra_" .. name] = extra_config
        end

        -- mark as override
        scope["__override_" .. name] = true

        -- get patterns
        local patterns = {}
        if #args > 1 then
            patterns = table.slice(args, 1, #args - 1)
        end

        -- get script function or name
        local script_func_or_name = args[#args]

        -- get script
        local script, errors = self:_script(script_func_or_name)
        if not script then
            if #patterns > 0 then
                os.raise("%s_%s(%s, %s): %s", action, name, table.concat(patterns, ', '), tostring(script_func_or_name), errors)
            else
                os.raise("%s_%s(%s): %s", action, name, tostring(script_func_or_name), errors)
            end
        end

        -- save script for all patterns
        if #patterns > 0 then
            local scripts = scope[name] or {}
            for _, pattern in ipairs(patterns) do

                -- check
                assert(type(pattern) == "string")

                -- convert pattern to a lua pattern ('*' => '.*')
                pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
                pattern = pattern:gsub("%*", "\001")
                pattern = pattern:gsub("\001", ".*")

                -- save script
                if type(scripts) == "table" then
                    scripts[pattern] = script
                elseif type(scripts) == "function" then
                    scripts = {__generic__ = scripts}
                    scripts[pattern] = script
                end
            end
            scope[name] = scripts
        else
            -- save the generic script
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

-- translate api paths
function interpreter:_api_translate_paths(values, apiname, infolevel)
    local results = {}
    for _, p in ipairs(values) do
        if type(p) ~= "string" or #p == 0 then
            local sourceinfo = debug.getinfo(infolevel or 3, "Sl")
            os.raise("%s(%s): invalid path value at %s:%d", apiname, tostring(p), sourceinfo.short_src or sourceinfo.source, sourceinfo.currentline)
        end
        if not p:find("^%s-%$%(.-%)") and not path.is_absolute(p) then
            table.insert(results, path.relative(path.absolute(p, self:scriptdir()), self:rootdir()))
        else
            table.insert(results, p)
        end
    end
    return results
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

-- set api function within scope
function interpreter:_api_within_scope_set(scope_kind, apiname, apifunc)

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
            api_scope[apiname] = apifunc
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
function interpreter:_filter(values, level)

    -- check
    assert(self and values ~= nil)

    -- return values directly if no filter
    local filter = self._PRIVATE._FILTER
    if filter == nil then
        return values
    end

    -- init level
    if level == nil then
        level = 0
    end

    -- filter keyvalues
    if table.is_dictionary(values) then
        local results = {}
        for key, value in pairs(values) do
            key = filter:handle(key)
            if type(value) == "string" then
                results[key] = filter:handle(value)
            elseif type(value) == "table" and level < 1 then
                results[key] = self:_filter(value, level + 1) -- only filter 2 levels for table values
            else
                results[key] = value
            end
            values = results
        end
    else
        -- filter value or arrays
        values = table.wrap(values)
        for idx = 1, table.maxn(values) do

            local value = values[idx]
            if type(value) == "string" then
                value = filter:handle(value)
            elseif table.is_array(value) then
                for i = 1, table.maxn(value) do
                    local v = value[i]
                    if type(v) == "string" then
                        v = filter:handle(v)
                    elseif type(v) == "table" and level < 1 then
                        v = self:_filter(v, level + 1)
                    end
                    value[i] = v
                end
            end
            values[idx] = value
        end
    end
    return values
end

-- handle scope data
function interpreter:_handle(scope, remove_repeat, enable_filter)

    -- check
    assert(scope)

    -- remove repeat values and unwrap it
    local results = {}
    for name, values in pairs(scope) do

        -- remove repeat first for each slice with deleted item (__del_xxx)
        if remove_repeat and not table.is_dictionary(values) then
            values = table.unique(values, function (v) return type(v) == "string" and v:startswith("__del_") end)
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
        os.raise("the scope %s() is empty!", scope_kind)
    end

    -- get the root scope info of the given scope kind, e.g. root.target
    local results = {}
    local scope_opt = {interpreter = self, remove_repeat = remove_repeat, enable_filter = enable_filter}
    if scope_kind and scope_kind:startswith("root.") then

        local root_scope = scopes._ROOT[scope_kind:sub(6)]
        if root_scope then
            results = self:_handle(root_scope, remove_repeat, enable_filter)
        end
        return scopeinfo.new(scope_kind, results, scope_opt)

    -- get the root scope info without scope kind
    elseif scope_kind == "root" or scope_kind == nil then

        local root_scope = scopes._ROOT["__rootkind"]
        if root_scope then
            results = self:_handle(root_scope, remove_repeat, enable_filter)
        end
        return scopeinfo.new(scope_kind, results, scope_opt)

    -- get the results of the given scope kind
    elseif scope_kind then

        -- not this scope for kind?
        local scope_for_kind = scopes[scope_kind]
        if scope_for_kind then

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
                local scope_root = scopes._ROOT[scope_kind .. "@@" .. scope_name]
                if scope_root then
                    for name, values in pairs(scope_root) do
                        if not scope["__override_" .. name] then
                            scope_values[name] = table.join(values, scope_values[name] or {})
                        end
                    end
                end

                -- add this scope
                results[scope_name] = scopeinfo.new(scope_kind, self:_handle(scope_values, remove_repeat, enable_filter), scope_opt)
            end
        end
    end
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

-- get builtin modules
function interpreter._builtin_modules()
    local builtin_modules = interpreter._BUILTIN_MODULES
    if builtin_modules == nil then
        builtin_modules = {}
        local builtin_module_files = os.match(path.join(os.programdir(), "core/sandbox/modules/interpreter/*.lua"))
        if builtin_module_files then
            for _, builtin_module_file in ipairs(builtin_module_files) do

                -- the module name
                local module_name = path.basename(builtin_module_file)
                assert(module_name)

                -- load script
                local script, errors = loadfile(builtin_module_file)
                if script then

                    -- load module
                    local ok, results = utils.trycall(script)
                    if not ok then
                        os.raise(results)
                    end

                    -- save module
                    builtin_modules[module_name] = results
                else
                    -- error
                    os.raise(errors)
                end
            end
        end
        interpreter._BUILTIN_MODULES = builtin_modules
    end
    return builtin_modules
end

-- new an interpreter instance
function interpreter.new()

    -- init an interpreter instance
    local instance = {  _PUBLIC = {}
                    ,   _PRIVATE = {    _SCOPES = {}
                                    ,   _MTIMES = {}
                                    ,   _SCRIPT_FILES = {}
                                    ,   _FILTER = require("base/filter").new()}}

    -- inherit the interfaces of interpreter
    table.inherit2(instance, interpreter)

    -- dispatch the api calling for scope
    setmetatable(instance._PUBLIC, { __index = function (tbl, key)

                                            -- get interpreter instance
                                            if type(key) == "string" and key == "_INTERPRETER" and rawget(tbl, "_INTERPRETER_READABLE") then
                                                return instance
                                            end

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
                                    end
                                ,   __newindex = function (tbl, key, val)
                                        if type(key) == "string" and (key == "_INTERPRETER" or key == "_INTERPRETER_READABLE") then
                                            return
                                        end
                                        rawset(tbl, key, val)
                                    end})

    -- register the builtin interfaces
    instance:api_register(nil, "includes",     interpreter.api_builtin_includes)
    instance:api_register(nil, "add_subdirs",  interpreter.api_builtin_includes)
    instance:api_register(nil, "add_subfiles", interpreter.api_builtin_includes)
    instance:api_register(nil, "set_xmakever", interpreter.api_builtin_set_xmakever)

    -- register the builtin modules
    for module_name, module in pairs(interpreter._builtin_modules()) do
        instance:api_register_builtin(module_name, module)
    end

    -- ok?
    return instance
end

-- load script file, e.g. xmake.lua
--
-- @param opt   {on_load_data = function (data) return data end}
--
function interpreter:load(file, opt)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE and file)

    -- load the script
    opt = opt or {}
    local script, errors = loadfile(file, "bt", {on_load = opt.on_load_data})
    if not script then
        return nil, errors
    end

    -- clear first
    self:_clear()

    -- init the current file
    self._PRIVATE._CURFILE = file
    self._PRIVATE._SCRIPT_FILES = {file}

    -- init the root directory
    self._PRIVATE._ROOTDIR = path.directory(file)
    assert(self._PRIVATE._ROOTDIR)

    -- init mtime for the current file
    self._PRIVATE._MTIMES[path.relative(file, self._PRIVATE._ROOTDIR)] = os.mtime(file)

    -- bind public scope
    setfenv(script, self._PUBLIC)

    -- do interpreter
    return xpcall(script, interpreter._traceback)
end

-- make results
function interpreter:make(scope_kind, remove_repeat, enable_filter)

    -- get the results with the given scope
    local ok, results = xpcall(interpreter._make, interpreter._traceback, self, scope_kind, remove_repeat, enable_filter)
    if not ok then
        return nil, results
    end
    return results
end

-- get all loaded script files (xmake.lua)
function interpreter:scriptfiles()
    assert(self and self._PRIVATE)
    return self._PRIVATE._SCRIPT_FILES
end

-- get mtimes
function interpreter:mtimes()
    assert(self and self._PRIVATE)
    return self._PRIVATE._MTIMES
end

-- get filter
function interpreter:filter()
    assert(self and self._PRIVATE)
    return self._PRIVATE._FILTER
end

-- get root directory
function interpreter:rootdir()
    assert(self and self._PRIVATE)
    return self._PRIVATE._ROOTDIR
end

-- set root directory
function interpreter:rootdir_set(rootdir)
    assert(self and self._PRIVATE and rootdir)
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
    assert(self and self._PRIVATE)
    self._PRIVATE._ROOTSCOPE = scope_kind
end

-- get apis
function interpreter:apis(scope_kind)

    -- check
    assert(self and self._PRIVATE)

    -- get apis from the given scope kind
    if scope_kind and scope_kind ~= "__rootkind" then
        local apis = self._PRIVATE._APIS
        return apis and apis[scope_kind] or {}
    else
        return self._PRIVATE._ROOTAPIS or {}
    end
end

-- get api definitions
function interpreter:api_definitions()
    return self._API_DEFINITIONS
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
        scope[name] = function (...)
            return func(self, ...)
        end
    else

        -- get root apis
        self._PRIVATE._ROOTAPIS = self._PRIVATE._ROOTAPIS or {}
        local apis = self._PRIVATE._ROOTAPIS

        -- register api to the root scope
        apis[name] = function (...)
            return func(self, ...)
        end
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
    local implementation = function (self, scopes, scope_kind, scope_name, scope_info)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

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
            scopes._ROOT[scope_kind .. "@@" .. scope_name] = {}
        end

        -- with scope info? translate it
        --
        -- e.g.
        -- option("text", {showmenu = true, default = true, description = "test option"})
        -- target("tbox", {kind = "static", files = {"src/*.c", "*.cpp"}})
        --
        if scope_info and table.is_dictionary(scope_info) then
            for name, values in pairs(scope_info) do
                local apifunc = self:api_func("set_" .. name) or self:api_func("add_" .. name) or self:api_func("on_" .. name) or self:api_func(name)
                if apifunc then
                    apifunc(values)
                else
                    os.raise("unknown %s for %s(\"%s\")", name, scope_kind, scope_name)
                end
            end

            -- enter root scope
            scopes._CURRENT = nil
            scopes._CURRENT_KIND = nil
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

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then
            table.remove(values)
        else
            extra_config = nil
        end

        -- save values
        if #values > 0 then
            scope[name] = values
        else
            -- set("xx", nil)? remove it
            scope[name] = nil
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

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_values
function interpreter:api_register_add_values(scope_kind, ...)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then
            table.remove(values)
        else
            extra_config = nil
        end

        -- save values
        scope[name] = table.join2(scope[name] or {}, values)

        -- save extra config
        if extra_config then
            scope["__extra_" .. name] = scope["__extra_" .. name] or {}
            local extrascope = scope["__extra_" .. name]
            for _, value in ipairs(values) do
                extrascope[value] = extra_config
            end
        end
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- register api for set_keyvalues
--
-- interp:api_register_set_keyvalues("scope_kind", "name1", "name2", ...)
--
-- api:
--   set_$(name1)("key", "value1")
--   set_$(name2)("key", "value1", "value2", ...)
--
-- get:
--
--   get("name")     => {key => values}
--   get("name.key") => values
--
function interpreter:api_register_set_keyvalues(scope_kind, ...)

    -- define implementation
    local implementation = function (self, scope, name, key, ...)

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
        scope[name][key] = table.unwrap(values) -- expand values if only one

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

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for add_keyvalues
--
-- interp:api_register_add_keyvalues("scope_kind", "name1", "name2", ...)
--
function interpreter:api_register_add_keyvalues(scope_kind, ...)

    -- define implementation
    local implementation = function (self, scope, name, key, ...)

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
            -- expand values if only one
            scope[name][key] = table.unwrap(values)
        else
            scope[name][key] = table.join2(table.wrap(scope[name][key]), values)
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

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "add", implementation, ...)
end

-- register api for on_script
function interpreter:api_register_on_script(scope_kind, ...)
    self:_api_register_xxx_script(scope_kind, "on", ...)
end

-- register api for before_script
function interpreter:api_register_before_script(scope_kind, ...)
    self:_api_register_xxx_script(scope_kind, "before", ...)
end

-- register api for after_script
function interpreter:api_register_after_script(scope_kind, ...)
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
            scope[name] = {[dict_or_key] = value}
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

-- register api for set_paths
function interpreter:api_register_set_paths(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then
            table.remove(values)
        else
            extra_config = nil
        end

        -- translate paths
        local paths = self:_api_translate_paths(values, "set_" .. name)

        -- save values
        scope[name] = paths

        -- save extra config
        if extra_config then
            scope["__extra_" .. name] = scope["__extra_" .. name] or {}
            local extrascope = scope["__extra_" .. name]
            for _, value in ipairs(paths) do
                extrascope[value] = extra_config
            end
        end

        -- save api source info, e.g. call api() in sourcefile:linenumber
        self:_save_sourceinfo_to_scope(scope, name, paths)
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- register api for del_paths
function interpreter:api_register_del_paths(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- translate paths
        local values = {...}
        local paths = self:_api_translate_paths(values, "del_" .. name)

        -- mark these paths as deleted
        local paths_deleted = {}
        for _, pathname in ipairs(paths) do
            table.insert(paths_deleted, "__del_" .. pathname)
        end

        -- save values
        scope[name] = table.join2(scope[name] or {}, paths_deleted)

        -- save api source info, e.g. call api() in sourcefile:linenumber
        self:_save_sourceinfo_to_scope(scope, name, paths)
    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "del", implementation, ...)
end

-- register api for add_paths
function interpreter:api_register_add_paths(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, ...)

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then
            table.remove(values)
        else
            extra_config = nil
        end

        -- translate paths
        local paths = self:_api_translate_paths(values, "add_" .. name)

        -- save values
        scope[name] = table.join2(scope[name] or {}, paths)

        -- save extra config
        if extra_config then
            scope["__extra_" .. name] = scope["__extra_" .. name] or {}
            local extrascope = scope["__extra_" .. name]
            for _, value in ipairs(paths) do
                extrascope[value] = extra_config
            end
        end

        -- save api source info, e.g. call api() in sourcefile:linenumber
        self:_save_sourceinfo_to_scope(scope, name, paths)
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
--  ,   paths =
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

    -- register apis
    local scopes = {}
    local definitions = self._API_DEFINITIONS or {}
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

            -- register api definition, "scope.apiname" => "apitype"
            definitions[apifunc] = apitype

            -- get api function
            local apiscope = nil
            local funcname = nil
            apifunc = apifunc:split('.', {plain = true})
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
                for _, name in ipairs({"set", "add", "del", "on", "before", "after"}) do
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
    self._API_DEFINITIONS = definitions
end

-- the builtin api: set_xmakever()
function interpreter:api_builtin_set_xmakever(minver)

    -- no version
    if not minver then
        os.raise("[nobacktrace]: set_xmakever(): no version!")
    end

    -- parse minimum version
    local minvers = minver:split('.', {plain = true})
    if not minvers or #minvers ~= 3 then
        os.raise("[nobacktrace]: set_xmakever(\"%s\"): invalid version format!", minver)
    end

    -- make minimum numerical version
    local minvers_num = minvers[1] * 100 + minvers[2] * 10 + minvers[3]

    -- parse current version
    local curvers = xmake._VERSION_SHORT:split('.', {plain = true})

    -- make current numerical version
    local curvers_num = curvers[1] * 100 + curvers[2] * 10 + curvers[3]

    -- check version
    if curvers_num < minvers_num then
        os.raise("[nobacktrace]: xmake v%s < v%s, please run `$xmake update` to upgrade xmake!", xmake._VERSION_SHORT, minver)
    end
end

-- the builtin api: includes()
function interpreter:api_builtin_includes(...)

    -- check
    assert(self and self._PRIVATE and self._PRIVATE._ROOTDIR and self._PRIVATE._MTIMES)

    -- the current file
    local curfile = self._PRIVATE._CURFILE
    assert(curfile)

    -- the scopes
    local scopes = self._PRIVATE._SCOPES
    assert(scopes)

    -- get all subpaths
    local subpaths = table.join(...)

    -- find all files
    local subpaths_matched = {}
    for _, subpath in ipairs(subpaths) do
        -- find the given files from the project directory
        local files = os.match(subpath, not subpath:endswith(".lua"))
        if files and #files > 0 then
            table.join2(subpaths_matched, files)
        elseif not path.is_absolute(subpath) then
            -- attempt to find files from programdir/includes/*.lua
            files = os.files(path.join(os.programdir(), "includes", subpath))
            if files and #files > 0 then
                table.join2(subpaths_matched, files)
            end
        end
    end

    -- includes all files
    for _, subpath in ipairs(subpaths_matched) do
        if subpath and type(subpath) == "string" then

            -- the file path
            local file = subpath
            if not subpath:endswith(".lua") then
                file = path.join(subpath, path.filename(curfile))
            end

            -- get the absolute file path
            if not path.is_absolute(file) then
                file = path.absolute(file)
            end

            -- update the current file
            self._PRIVATE._CURFILE = file
            table.insert(self._PRIVATE._SCRIPT_FILES, file)

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
                local oldir = os.curdir()

                -- enter the script directory
                os.cd(path.directory(file))

                -- done interpreter
                local ok, errors = xpcall(script, interpreter._traceback)
                if not ok then
                    os.raise(errors)
                end

                -- leave the script directory
                os.cd(oldir)

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

-- get current instance in the interpreter modules
function interpreter.instance(script)

    -- get the sandbox instance from the given script
    local instance = nil
    if script then
        local scope = getfenv(script)
        if scope then

            -- enable to read _INTERPRETER
            rawset(scope, "_INTERPRETER_READABLE", true)

            -- attempt to get it
            instance = scope._INTERPRETER

            -- disable to read _INTERPRETER
            rawset(scope, "_INTERPRETER_READABLE", nil)
        end
        if instance then return instance end
    end

    -- find self instance for the current sandbox
    local level = 2
    while level < 32 do

        -- get scope
        local scope = getfenv(level)
        if scope then

            -- enable to read _INTERPRETER
            rawset(scope, "_INTERPRETER_READABLE", true)

            -- attempt to get it
            instance = scope._INTERPRETER

            -- disable to read _INTERPRETER
            rawset(scope, "_INTERPRETER_READABLE", nil)
        end

        -- found?
        if instance then
            break
        end

        -- next
        level = level + 1
    end

    -- ok?
    return instance
end

-- return module: interpreter
return interpreter
