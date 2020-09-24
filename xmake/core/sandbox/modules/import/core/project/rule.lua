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
-- @file        rule.lua
--

-- define module
local sandbox_core_project_rule = sandbox_core_project_rule or {}

-- load modules
local table     = require("base/table")
local rule      = require("project/rule")
local project   = require("project/project")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- get the given global rule
function sandbox_core_project_rule.rule(name)
    return rule.rule(name)
end

-- get the all global rules
function sandbox_core_project_rule.rules()
    return rule.rules()
end

-- return module
return sandbox_core_project_rule
