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
-- @file        config.lua
--

-- define module
local sandbox_core_project_config = sandbox_core_project_config or {}

-- load modules
local config    = require("project/config")
local project   = require("project/project")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_project_config.buildir   = config.buildir
sandbox_core_project_config.plat      = config.plat
sandbox_core_project_config.arch      = config.arch
sandbox_core_project_config.mode      = config.mode
sandbox_core_project_config.host      = config.host
sandbox_core_project_config.get       = config.get
sandbox_core_project_config.set       = config.set
sandbox_core_project_config.directory = config.directory
sandbox_core_project_config.filepath  = config.filepath
sandbox_core_project_config.readonly  = config.readonly
sandbox_core_project_config.load      = config.load
sandbox_core_project_config.read      = config.read
sandbox_core_project_config.clear     = config.clear
sandbox_core_project_config.dump      = config.dump

-- save the configuration
function sandbox_core_project_config.save(filepath, opt)
    local ok, errors = config.save(filepath, opt)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_project_config
