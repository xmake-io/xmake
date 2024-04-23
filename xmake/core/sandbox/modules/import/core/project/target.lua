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
-- @file        target.lua
--

-- define module
local sandbox_core_project_target = sandbox_core_project_target or {}

-- load modules
local target    = require("project/target")
local raise     = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_project_target.filename = target.filename
sandbox_core_project_target.linkname = target.linkname
sandbox_core_project_target.new      = target.new
sandbox_core_project_target.apis     = target.apis

-- return module
return sandbox_core_project_target
