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
-- @file        theme.lua
--

-- define module
local sandbox_core_theme = sandbox_core_theme or {}

-- load modules
local theme     = require("theme/theme")
local raise     = require("sandbox/modules/raise")

-- get the current theme instance
function sandbox_core_theme.instance()
    local instance = theme.instance()
    if instance ~= nil then
        return instance
    else
        raise("cannot get the current theme")
    end
end

-- load the given theme
function sandbox_core_theme.load(name)
    local instance, errors = theme.load(name)
    if not instance then
        raise("load theme(%s) failed, %s", name, errors)
    end
    return instance
end

-- get the theme configuration
function sandbox_core_theme.get(name)
    local value = theme.get(name)
    if value ~= nil then
        return value
    else
        local instance = theme.instance()
        raise("cannot get %s from the current theme(%s)", name, instance and instance:name() or "unknown")
    end
end

-- find all themes
function sandbox_core_theme.names()
    return theme.names()
end

-- return module
return sandbox_core_theme
