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
-- @file        deprecated_interpreter.lua
--

-- define module: deprecated_interpreter
local deprecated_interpreter = deprecated_interpreter or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local utils         = require("base/utils")
local string        = require("base/string")
local deprecated    = require("base/deprecated")
local sandbox       = require("sandbox/sandbox")

-- register api for set_scope()
function deprecated_interpreter:api_register_set_scope(...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- deprecated
        if not scope_name:startswith("__") then
            deprecated.add("%s(\"%s\")", "set_%s(\"%s\")", scope_kind, scope_name)
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
    self:_api_register_scope_api(nil, "set", implementation, ...)
end

-- register api for add_scope()
function deprecated_interpreter:api_register_add_scope(...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scopes, scope_kind, scope_name)

        -- init scope for kind
        local scope_for_kind = scopes[scope_kind] or {}
        scopes[scope_kind] = scope_for_kind

        -- deprecated
        if not scope_name:startswith("__") then
            deprecated.add("%s(\"%s\")", "add_%s(\"%s\")", scope_kind, scope_name)
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
    self:_api_register_scope_api(nil, "add", implementation, ...)
end

-- register api for set_script
function deprecated_interpreter:api_register_set_script(scope_kind, ...)

    -- check
    assert(self)

    -- define implementation
    local implementation = function (self, scope, name, script)

        -- deprecated
        deprecated.add("on_%s()", "set_%s()", name)

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, self:filter(), self:rootdir())
        if not instance then
            os.raise("set_%s(): %s", name, errors)
        end

        -- update script?
        scope[name] = {}
        table.insert(scope[name], instance:script())

    end

    -- register implementation
    self:_api_register_xxx_values(scope_kind, "set", implementation, ...)
end

-- return module: deprecated_interpreter
return deprecated_interpreter
