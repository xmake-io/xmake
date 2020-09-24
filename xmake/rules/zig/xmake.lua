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

-- define rule: zig.build
rule("zig.build")
    set_sourcekinds("zc")
    on_build_files("private.action.build.object", {batch = true})

-- define rule: zig
rule("zig")

    -- add build rules
    add_deps("zig.build")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")
