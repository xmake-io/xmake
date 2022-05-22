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

rule("qt.qrc")
    add_deps("qt.env")
    set_extensions(".qrc")
    on_load(function (target)

        -- get rcc
        local qt = assert(target:data("qt"), "qt not found!")
        local rcc = path.join(qt.bindir, is_host("windows") and "rcc.exe" or "rcc")
        if not os.isexec(rcc) and qt.libexecdir then
            rcc = path.join(qt.libexecdir, is_host("windows") and "rcc.exe" or "rcc")
        end
        if not os.isexec(rcc) and qt.libexecdir_host then
            rcc = path.join(qt.libexecdir_host, is_host("windows") and "rcc.exe" or "rcc")
        end
        assert(os.isexec(rcc), "rcc not found!")

        -- save rcc
        target:data_set("qt.rcc", rcc)
    end)

    on_buildcmd_file(function (target, batchcmds, sourcefile_qrc, opt)

        -- get rcc
        local rcc = target:data("qt.rcc")

        -- get c++ source file for qrc
        local sourcefile_cpp = path.join(target:autogendir(), "rules", "qt", "qrc", path.basename(sourcefile_qrc) .. ".cpp")
        local sourcefile_dir = path.directory(sourcefile_cpp)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cpp)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.qrc %s", sourcefile_qrc)
        batchcmds:mkdir(sourcefile_dir)
        batchcmds:vrunv(rcc, {"-name", path.basename(sourcefile_qrc), path(sourcefile_qrc), "-o", path(sourcefile_cpp)})
        batchcmds:compile(sourcefile_cpp, objectfile)

        -- get qrc resources files
        local outdata = os.iorunv(rcc, {"-name", path.basename(sourcefile_qrc), sourcefile_qrc, "-list"})

        -- add resources files to batch
        for _, file in ipairs(outdata:split("\n")) do
            batchcmds:add_depfiles(file)
        end

        -- add deps
        batchcmds:add_depfiles(sourcefile_qrc)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

