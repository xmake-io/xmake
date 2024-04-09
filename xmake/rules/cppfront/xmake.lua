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

rule("cppfront.build.h2")
    set_extensions(".h2")

    on_buildcmd_file(function (target, batchcmds, sourcefile_h2, opt)
        -- get cppfront
        import("lib.detect.find_tool")
        local cppfront = assert(find_tool("cppfront", {check = "-h"}), "cppfront not found!")

        -- get h header file for h2
        local sourcefile_h = target:autogenfile((sourcefile_h2:gsub(".h2$", ".h")))
        local basedir = path.directory(sourcefile_h)

        -- add commands
        local argv = {"-o", path(sourcefile_h), path(sourcefile_h2)}
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.h2 %s", sourcefile_h2)
        batchcmds:mkdir(basedir)
        batchcmds:vrunv(cppfront.program, argv)

        -- add deps
        batchcmds:add_depfiles(sourcefile_h2)
        batchcmds:set_depmtime(os.mtime(sourcefile_h))
        batchcmds:set_depcache(target:dependfile(sourcefile_h))
    end)

-- define rule: cppfront.build
rule("cppfront.build.cpp2")
    set_extensions(".cpp2")

    -- .h2 must compile before .cpp2
    add_deps("cppfront.build.h2", {order = true})

    on_load(function (target)
        -- only cppfront source files? we need to patch cxx source kind for linker
        local sourcekinds = target:sourcekinds()
        if #sourcekinds == 0 then
            table.insert(sourcekinds, "cxx")
        end
        local cppfront = target:pkg("cppfront")
        if cppfront and cppfront:installdir() then
            local includedir = path.join(cppfront:installdir(), "include")
            if os.isdir(includedir) then
                target:add("includedirs", includedir)
            end
        end
    end)
    on_buildcmd_file(function (target, batchcmds, sourcefile_cpp2, opt)
        -- get cppfront
        import("lib.detect.find_tool")
        local cppfront = assert(find_tool("cppfront", {check = "-h"}), "cppfront not found!")

        -- get c++ source file for cpp2
        local sourcefile_cpp = target:autogenfile((sourcefile_cpp2:gsub(".cpp2$", ".cpp")))
        local basedir = path.directory(sourcefile_cpp)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cpp)
        table.insert(target:objectfiles(), objectfile)

        -- add_depfiles for #include "xxxx/xxxx/xxx.h2" ,exclude // #include "xxxx.h2"
        local root_dir = path.directory(sourcefile_cpp2)
        for line in io.lines(sourcefile_cpp2) do
            local match_h2 = line:match("^ -#include *\"([%w%p]+.h2)\"")
            if match_h2 ~= nil then
                batchcmds:add_depfiles(path.join(root_dir, match_h2))
            end
        end
        -- add commands
        local argv = {"-o", path(sourcefile_cpp), path(sourcefile_cpp2)}
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.cpp2 %s", sourcefile_cpp2)
        batchcmds:mkdir(basedir)
        batchcmds:vrunv(cppfront.program, argv)
        batchcmds:compile(sourcefile_cpp, objectfile, {configs = {languages = "c++20"}})

        -- add deps
        batchcmds:add_depfiles(sourcefile_cpp2)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)


-- define rule: cppfront
rule("cppfront")

    -- add_build.h2 rules
    add_deps("cppfront.build.h2")

    -- add build rules
    add_deps("cppfront.build.cpp2")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")

