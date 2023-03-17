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
-- @file        profiler.lua
--

-- define module
local sandbox_core_base_profiler = sandbox_core_base_profiler or {}

-- load modules
local profiler = require("base/profiler")
local raise    = require("sandbox/modules/raise")

-- enter tag
function sandbox_core_base_profiler.enter(name, ...)
    profiler:enter(name, ...)
end

-- leave tag
function sandbox_core_base_profiler.leave(name, ...)
    profiler:leave(name, ...)
end

-- return module
return sandbox_core_base_profiler

