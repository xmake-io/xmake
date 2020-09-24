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
-- @file        winos.lua
--

-- load modules
local winos = require("base/winos")
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_winos = sandbox_winos or {}

-- inherit some builtin interfaces
sandbox_winos.oem_cp            = winos.oem_cp
sandbox_winos.ansi_cp           = winos.ansi_cp
sandbox_winos.cp_info           = winos.cp_info
sandbox_winos.console_cp        = winos.console_cp
sandbox_winos.console_output_cp = winos.console_output_cp
sandbox_winos.registry_query    = winos.registry_query
sandbox_winos.logical_drives    = winos.logical_drives
sandbox_winos.cmdargv           = winos.cmdargv

-- get windows system version
function sandbox_winos.version()
    local winver = winos.version()
    if not winver then
        raise("cannot get the version of the current winos!")
    end
    return winver
end

-- return module
return sandbox_winos

