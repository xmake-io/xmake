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
-- @file        main.lua
--

-- imports
import("rules.c++.config.basic", {rootdir = os.programdir(), alias = "config_basic"})
import("rules.c++.config.dynamic_debugging", {rootdir = os.programdir(), alias = "config_dynamic_debugging"})
import("rules.c++.config.optimization", {rootdir = os.programdir(), alias = "config_optimization"})
import("rules.c++.config.sanitizer", {rootdir = os.programdir(), alias = "config_sanitizer"})

-- main entry
function main(target, sourcekind)

    -- config basic configs
    config_basic(target, sourcekind)

    -- config dynamic debugging configs (must be before optimization to disable incompatible flags)
    config_dynamic_debugging(target, sourcekind)

    -- config optimization configs
    config_optimization(target, sourcekind)

    -- config sanitizer configs
    config_sanitizer(target, sourcekind)
end

