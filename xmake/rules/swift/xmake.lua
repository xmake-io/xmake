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

-- define rule: swift.build
rule("swift.build")
    set_sourcekinds("sc")
    on_build_files("private.action.build.object", {batch = true})

-- define rule: swift
rule("swift")

    -- add build rules
    add_deps("swift.build")

    -- support `add_files("src/*.o")` to merge object files to target
    add_deps("utils.merge.object")

    -- check targets
    add_deps("utils.check.targets")
