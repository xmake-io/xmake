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

-- export some readonly interfaces
sandbox_core_base_global.get       = global.get
sandbox_core_base_global.set       = global.set
sandbox_core_base_global.readonly  = global.readonly
sandbox_core_base_global.dump      = global.dump
sandbox_core_base_global.clear     = global.clear
sandbox_core_base_global.options   = global.options
sandbox_core_base_global.filepath  = global.filepath
sandbox_core_base_global.directory = global.directory
sandbox_core_base_global.cachedir  = global.cachedir

-- save the configure
function sandbox_core_base_global.save()
    local ok, errors = global.save()
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_base_global
