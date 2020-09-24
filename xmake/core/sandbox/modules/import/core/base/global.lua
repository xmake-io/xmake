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
-- @file        global.lua
--

-- define module
local sandbox_core_base_global = sandbox_core_base_global or {}

-- load modules
local os        = require("base/os")
local table     = require("base/table")
local global    = require("base/global")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the configure
function sandbox_core_base_global.get(name)
    return global.get(name)
end

-- set the configure
--
-- @param name  the name
-- @param value the value
-- @param opt   the argument options, e.g. {readonly = false, force = false}
--
function sandbox_core_base_global.set(name, value, opt)
    global.set(name, value, opt)
end

-- this config name is readonly?
function sandbox_core_base_global.readonly(name)
    return config.readonly(name)
end

-- dump the configure
function sandbox_core_base_global.dump()
    global.dump()
end

-- save the configure
function sandbox_core_base_global.save()

    -- save it
    local ok, errors = global.save()
    if not ok then
        raise(errors)
    end
end

-- clear the configure
function sandbox_core_base_global.clear()
    return global.clear()
end

-- get all options
function sandbox_core_base_global.options()
    return global.options()
end

-- get the configure file path
function sandbox_core_base_global.filepath()
    local filepath = global.filepath()
    assert(filepath)
    return filepath
end

-- get the configure directory
function sandbox_core_base_global.directory()
    local dir = global.directory()
    assert(dir)
    return dir
end

-- return module
return sandbox_core_base_global
