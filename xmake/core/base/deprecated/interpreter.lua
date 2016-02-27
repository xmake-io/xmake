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
-- @file        deprecated_interpreter.lua
--

-- define module: deprecated_interpreter
local deprecated_interpreter = deprecated_interpreter or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")
local sandbox   = require("base/sandbox")

-- register api for set_scope()
function deprecated_interpreter.api_register_set_scope(self, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- warning
        if not scope_name:startswith("__") then
            utils.warning("please uses %s(\"%s\"), \"set_%s\" has been deprecated!", scope_kind, scope_name, scope_kind)
        end

        -- check 
        if not scope_for_kind[scope_name] then
            utils.error("set_%s(\"%s\") failed, %s not found!", scope_kind, scope_name, scope_name)
            os.raise("please uses add_%s(\"%s\") first!", scope_kind, scope_name)
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
function deprecated_interpreter.api_register_add_scope(self, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- warning
        if not scope_name:startswith("__") then
            utils.warning("please uses %s(\"%s\"), \"add_%s\" has been deprecated!", scope_kind, scope_name, scope_kind)
        end

        -- check 
        if scope_for_kind[scope_name] then
            utils.error("add_%s(\"%s\") failed, %s have been defined!", scope_kind, scope_name, scope_name)
            os.raise("please uses set_%s(\"%s\")!", scope_kind, scope_name)
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

-- register api for set_script
function deprecated_interpreter.api_register_set_script(self, scope_kind, prefix, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- warning
        utils.warning("please uses on_%s(), \"set_%s()\" has been deprecated!", name, name, scope)

        -- bind script and get new script with sandbox
        local newscript, errors = sandbox.bind(script, self)
        if not newscript then
            os.raise("set_%s(): %s", name, errors)
        end

        -- update script?
        scope[name] = {}
        table.insert(scope[name], newscript)

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", prefix, implementation, ...)
end

-- return module: deprecated_interpreter
return deprecated_interpreter
