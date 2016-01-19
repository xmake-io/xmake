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
function interpreter._register_api_xxx_(self, action, apifunc, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(action and apifunc)

    -- done
    for _, apiname in ipairs({...}) do

        -- check
        assert(apiname)

        -- register scope api
        self:register_api(action .. "_" .. apiname, function (...) 
       
            -- check
            assert(self and self._PRIVATE and apiname)

            -- the scopes
            local scopes = self._PRIVATE._SCOPES
            assert(scopes)

            -- call function
            apifunc(scopes, apiname, ...) 
        end)
    end
end

-- init interpreter
function interpreter.init()

    -- init an interpreter instance
    local interp = {    _PUBLIC = {}
                    ,   _PRIVATE = {_SCOPES = {}}}

    -- inherit the interfaces of interpreter
    for k, v in pairs(interpreter) do
        if type(v) == "function" then
            interp[k] = v
        end
    end

    -- ok?
    return interp
end

-- load interpreter 
function interpreter.load(self, file)

    -- check
    assert(self and self._PUBLIC and file)

    -- load the script
    local script = loadfile(file)
    if not script then
        return nil, string.format("load %s failed!", file)
    end

    -- bind public scope
    setfenv(script, self._PUBLIC)

    -- done interpreter
    return xpcall(script, interpreter._traceback)
end

-- register api 
function interpreter.register_api(self, name, func)

    -- check
    assert(self and self._PUBLIC)
    assert(name and func)

    -- register it
    self._PUBLIC[name] = func
end

-- register api for set_scope()
--
-- interp:register_api_set_scope("scope_kind1", "scope_kind2")
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
function interpreter.register_api_set_scope(self, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- define implementation
    local implementation = function (scopes, scope_kind, scope_name)

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
    self:_register_api_xxx_("set", implementation, ...)
end

-- register api for add_scope()
function interpreter.register_api_add_scope(self, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- define implementation
    local implementation = function (scopes, scope_kind, scope_name)

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
    self:_register_api_xxx_("add", implementation, ...)
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
--              }
--          }
--
--          scope_kind
--          {  
--              "scope_name" <-- _SCOPES._CURRENT
--              {
--                  name1 = {"value1"}
--                  name2 = {"value1", "value2", ...}
--              }
--          }
--      }
-- }
--
function interpreter.register_api_set_values(self, scope_kind, prefix, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE and scope_kind)

    -- define implementation
    local implementation = function (scopes, name, ...)

        -- init root scopes
        scopes._ROOT = scopes._ROOT or {}

        -- init current root scope
        local root = scopes._ROOT[scope_kind] or {}
        scopes._ROOT[scope_kind] = root

        -- the current scope
        local scope = scopes._CURRENT or root
        assert(scope)

        -- update values?
        scope[name] = {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    action = "set"
    if prefix then action = "set_" .. prefix end
    self:_register_api_xxx_(action, implementation, ...)
end

-- register api for add_values
function interpreter.register_api_add_values(self, scope_kind, prefix, ...)

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)
    assert(scope_kind)

    -- define implementation
    local implementation = function (scopes, name, ...)

        -- init root scopes
        scopes._ROOT = scopes._ROOT or {}

        -- init current root scope
        local root = scopes._ROOT[scope_kind] or {}
        scopes._ROOT[scope_kind] = root

        -- the current scope
        local scope = scopes._CURRENT or root
        assert(scope)

        -- append values?
        scope[name] = scope[name] or {}
        table.join2(scope[name], ...)

    end

    -- register implementation
    action = "add"
    if prefix then action = "add_" .. prefix end
    self:_register_api_xxx_(action, implementation, ...)
end

-- return module: interpreter
return interpreter
