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
-- @file        winos.lua
--

-- load modules
local winos = require("base/winos")
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_winos = sandbox_winos or {}

-- inherit some builtin interfaces
sandbox_winos.oem_cp                  = winos.oem_cp
sandbox_winos.ansi_cp                 = winos.ansi_cp
sandbox_winos.cp_info                 = winos.cp_info
sandbox_winos.console_cp              = winos.console_cp
sandbox_winos.console_output_cp       = winos.console_output_cp
sandbox_winos.logical_drives          = winos.logical_drives
sandbox_winos.cmdargv                 = winos.cmdargv
sandbox_winos.inherit_handles_safely  = winos.inherit_handles_safely

-- get windows system version
function sandbox_winos.version()
    local winver = winos.version()
    if not winver then
        raise("cannot get the version of the current winos!")
    end
    return winver
end

-- query registry value
function sandbox_winos.registry_query(keypath)
    local value, errors = winos.registry_query(keypath)
    if not value then
        raise(errors)
    end
    return value
end

-- get registry keys
function sandbox_winos.registry_keys(keypath)
    local keys, errors = winos.registry_keys(keypath)
    if not keys then
        raise(errors)
    end
    return keys
end

-- get registry values
function sandbox_winos.registry_values(keypath)
    local values, errors = winos.registry_values(keypath)
    if not values then
        raise(errors)
    end
    return values
end

-- get short path
function sandbox_winos.short_path(long_path)
    local short_path, errors = winos.short_path(long_path)
    if not short_path then
        raise(errors)
    end
    return short_path
end

-- return module
return sandbox_winos

