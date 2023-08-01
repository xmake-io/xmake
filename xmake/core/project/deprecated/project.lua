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
-- @file        deprecated_project.lua
--

-- define module: deprecated_project
local deprecated_project = deprecated_project or {}

-- load modules
local os                        = require("base/os")
local path                      = require("base/path")
local utils                     = require("base/utils")
local table                     = require("base/table")
local string                    = require("base/string")
local rule                      = require("project/rule")
local config                    = require("project/config")
local platform                  = require("platform/platform")
local deprecated                = require("base/deprecated")

-- register api
function deprecated_project.api_register(interp)
end

-- return module: deprecated_project
return deprecated_project
