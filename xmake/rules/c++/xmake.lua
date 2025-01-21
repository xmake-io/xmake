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

rule("c.build")
    set_sourcekinds("cc")
    add_deps("c.build.pcheader", "c.build.optimization", "c.build.sanitizer")
    on_build_files("private.action.build.object", {batch = true, distcc = true})
    on_config(function (target)
        -- enable vs runtime as MD by default
        if target:is_plat("windows") and not target:get("runtimes") then
            local vs_runtime_default = target:policy("build.c++.msvc.runtime")
            if vs_runtime_default and target:has_tool("cc", "cl", "clang_cl") then
                if is_mode("debug") then
                    vs_runtime_default = vs_runtime_default .. "d"
                end
                target:set("runtimes", vs_runtime_default)
            end
        end
        -- https://github.com/xmake-io/xmake/issues/4621
        if target:is_plat("windows") and target:is_static() and target:has_tool("cc", "tcc") then
            target:set("extension", ".a")
            target:set("prefixname", "lib")
        end
    end)

rule("c++.build")
    set_sourcekinds("cxx")
    add_deps("c++.build.pcheader", "c++.build.modules", "c++.build.optimization", "c++.build.sanitizer")
    on_build_files("private.action.build.object", {batch = true, distcc = true})
    on_config(function (target)
        -- enable c++ exceptions by default
        if target:is_plat("windows") and not target:get("exceptions") then
            target:set("exceptions", "cxx")
        end
        -- enable vs runtime as MD by default
        if target:is_plat("windows") and not target:get("runtimes") then
            local vs_runtime_default = target:policy("build.c++.msvc.runtime")
            if vs_runtime_default and target:has_tool("cxx", "cl", "clang_cl") then
                if is_mode("debug") then
                    vs_runtime_default = vs_runtime_default .. "d"
                end
                target:set("runtimes", vs_runtime_default)
            end
        end
        -- https://github.com/xmake-io/xmake/issues/4621
        if target:is_plat("windows") and target:is_static() and target:has_tool("cxx", "tcc") then
            target:set("extension", ".a")
            target:set("prefixname", "lib")
        end
    end)

rule("c")

    -- add build rules
    add_deps("c.build")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")

    -- add platform rules
    add_deps("platform.wasm")
    add_deps("platform.windows")

    -- add linker rules
    add_deps("linker")

rule("c++")

    -- add build rules
    add_deps("c++.build")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")

    -- add platform rules
    add_deps("platform.wasm")
    add_deps("platform.windows")

    -- add linker rules
    add_deps("linker")

