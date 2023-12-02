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

rule("c++.build")
    set_sourcekinds("cxx")
    add_deps("c++.build.pcheader", "c++.build.modules", "c++.build.optimization", "c++.build.sanitizer")
    on_build_files("private.action.build.object", {batch = true, distcc = true})
    on_config(function (target)
        -- we enable c++ exceptions by default
        if target:is_plat("windows") and not target:get("exceptions") then
            target:set("exceptions", "cxx")
        end

        -- if clang.libc++ policy is set, append stdlib flags
        if target:has_tool("cxx", "clang", "clangxx") and target:policy("build.c++.clang.libcxx") then
            local stdlibflag = "-stdlib=libc++"
            target:add("cxxflags", stdlibflag)
            target:add("mxflags", stdlibflag)

            -- on windows, the hookup for using it automatically with -stdlib=libc++ is missing for MSVC configs, so you basically need to manually add the include directories for it
            if is_host("windows") and not is_subhost("msys") then
                import("lib.detect.find_path")
                local compiler = target:compiler("cxx"):program()
                local toolchain_root = path.is_absolute(compiler) and path.directory(compiler) or find_path(compiler, os.getenv("PATH"):split(";", {plain = true}))
                assert(toolchain_root, "can't find llvm root directory !")
                toolchain_root = path.join(toolchain_root, "..")
                local cxx_includedirflag = "-cxx-isystem" .. path.join(toolchain_root, "include", "c++", "v1")
                target:add("cxxflags", cxx_includedirflag)
                target:add("mxflags", cxx_includedirflag)
                target:add("linkdirs", path.join(toolchain_root, "lib"))
            end
        end
    end)

rule("c++")

    -- add build rules
    add_deps("c++.build", "c.build")

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

