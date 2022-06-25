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
-- @file        policy.lua
--

-- define module
local sandbox_core_project_policy = sandbox_core_project_policy or {}

-- load modules
local table       = require("base/table")
local global      = require("base/global")
local option      = require("base/option")
local policy      = require("project/policy")
local project     = require("project/project")
local raise       = require("sandbox/modules/raise")

-- export some readonly interfaces
sandbox_core_project_policy.policies = policy.policies

-- has build warnings?
function sandbox_core_project_policy.build_warnings()
    local warnings = sandbox_core_project_policy._BUILD_WARNINGS
    if warnings == nil then
        warnings = option.get("diagnosis") or option.get("warning")
        if warnings == nil and os.isfile(os.projectfile()) and project.policy("build.warning") ~= nil then
            warnings = project.policy("build.warning")
        end
        if warnings == nil then
            warnings = global.get("build_warning")
        end
        sandbox_core_project_policy._BUILD_WARNINGS = warnings or false
    end
    return warnings
end

-- return module
return sandbox_core_project_policy
