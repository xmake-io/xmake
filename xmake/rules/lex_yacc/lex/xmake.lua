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

-- define rule: lex
rule("lex")
    add_deps("c++")
    set_extensions(".l", ".ll")
    on_buildcmd_file(function (target, batchcmds, sourcefile_lex, opt)

        -- get lex
        import("lib.detect.find_tool")
        local lex = assert(find_tool("flex") or find_tool("lex"), "lex not found!")

        -- get c/c++ source file for lex
        local extension = path.extension(sourcefile_lex)
        local sourcefile_cx = path.join(target:autogendir(), "rules", "lex_yacc", path.basename(sourcefile_lex) .. (extension == ".ll" and ".cpp" or ".c"))

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cx)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.lex %s", sourcefile_lex)
        batchcmds:mkdir(path.directory(sourcefile_cx))
        batchcmds:vrunv(lex.program, {"-o", path(sourcefile_cx), path(sourcefile_lex)})
        batchcmds:compile(sourcefile_cx, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile_lex)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

