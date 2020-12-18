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
-- @file        template.lua
--

-- define module
local sandbox_core_project_template = sandbox_core_project_template or {}

-- load modules
local template  = require("project/template")
local raise     = require("sandbox/modules/raise")

-- get all languages
function sandbox_core_project_template.languages()
    return assert(template.languages())
end

-- load all templates from the given language
function sandbox_core_project_template.templates(language)
    return assert(template.templates(language))
end

-- return module
return sandbox_core_project_template
