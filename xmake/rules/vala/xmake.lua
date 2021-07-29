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

rule("vala")
    set_extensions(".vala")
    before_buildcmd_file(function (target, batchcmds, sourcefile_vala, opt)

        -- get valac
        import("lib.detect.find_tool")
        local valac = assert(find_tool("valac"), "valac not found!")

        -- get c source file for vala
        local sourcefile_c = path.join(target:autogendir(), "rules", "vala", path.basename(sourcefile_vala) .. ".c")
        local basedir = path.directory(sourcefile_c)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_c)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.vala %s", sourcefile_vala)
        batchcmds:mkdir(basedir)
        local argv = {"-C", "-b", basedir}
        local packages = target:values("vala.packages")
        if packages then
            for _, package in ipairs(packages) do
                table.insert(argv, "--pkg")
                table.insert(argv, package)
            end
        end
        table.insert(argv, sourcefile_vala)
        batchcmds:vrunv(valac.program, argv)
        batchcmds:compile(sourcefile_c, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile_vala)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

