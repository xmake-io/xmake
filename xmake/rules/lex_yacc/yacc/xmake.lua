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

-- define rule: yacc
rule("yacc")
    add_deps("c++")
    set_extensions(".y", ".yy")
    on_load(function (target)
        local sourcefile_dir = path.join(target:autogendir(), "rules", "yacc_yacc")
        target:add("includedirs", sourcefile_dir)
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_yacc, opt)

        -- get yacc
        import("lib.detect.find_tool")
        local yacc = assert(find_tool("bison") or find_tool("yacc"), "yacc/bison not found!")

        -- get c/c++ source file for yacc
        local extension = path.extension(sourcefile_yacc)
        local sourcefile_cx = path.join(target:autogendir(), "rules", "yacc_yacc", path.basename(sourcefile_yacc) .. ".tab" .. (extension == ".yy" and ".cpp" or ".c"))

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cx)
        table.insert(target:objectfiles(), objectfile)

        -- add includedirs
        local sourcefile_dir = path.directory(sourcefile_cx)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.yacc %s", sourcefile_yacc)
        batchcmds:mkdir(sourcefile_dir)
        batchcmds:vrunv(yacc.program, {"-d", "-o", path(sourcefile_cx), path(sourcefile_yacc)})
        batchcmds:compile(sourcefile_cx, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile_yacc)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

