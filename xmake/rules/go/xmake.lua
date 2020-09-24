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
-- @file        xmake.lua
--

rule("go.build")
    set_sourcekinds("gc")
    add_deps("go.env")
    on_load(function (target)
        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        target:set("policy", "build.across_targets_in_parallel", false)
    end)
    on_build_files("build.object")

rule("go")

    -- add build rules
    add_deps("go.build")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")
