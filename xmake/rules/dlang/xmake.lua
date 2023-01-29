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
-- @file        xmake.lua
--

rule("dlang.build")
    set_sourcekinds("dc")
    add_deps("dlang.build.optimization")
    on_build_files("private.action.build.object", {batch = true})
    on_load(function (target)
        local toolchains = target:get("toolchains") or get_config("toolchain")
        if not toolchains or not table.contains(table.wrap(toolchains), "dlang", "dmd", "ldc", "gdc") then
            target:add("toolchains", "dlang")
        end
    end)

rule("dlang")

    -- add build rules
    add_deps("dlang.build")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")

    -- add linker rules
    add_deps("linker")

