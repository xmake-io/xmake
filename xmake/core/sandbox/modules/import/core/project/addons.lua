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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        addons.lua
--

-- define module
local sandbox_core_project_addons = sandbox_core_project_addons or {}

-- load modules
local addons = require("project/addons")
local raise  = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_project_addons.file         = addons.file
sandbox_core_project_addons.filename     = addons.filename
sandbox_core_project_addons.lockfile     = addons.lockfile
sandbox_core_project_addons.locked       = addons.locked
sandbox_core_project_addons.locked_valid = addons.locked_valid
sandbox_core_project_addons.requirename  = addons.requirename
sandbox_core_project_addons.satisfied    = addons.satisfied

-- load the declared addons of the given project directory
--
-- @param projectdir the project directory
-- @return           the addons information, it will be nil if this project declares nothing
--
function sandbox_core_project_addons.load(projectdir)
    local addonsinfo, errors = addons.load(projectdir)
    if errors then
        raise(errors)
    end
    return addonsinfo
end

-- return module
return sandbox_core_project_addons
