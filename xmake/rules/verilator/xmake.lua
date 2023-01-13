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

rule("verilator.binary")
    set_extensions(".v")
    on_load(function (target)
        target:set("kind", "binary")
    end)

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        local toolchain = assert(target:toolchain("verilator"), 'we need set_toolchains("verilator") in target("%s")', target:name())
        local verilator = assert(toolchain:config("verilator"), "verilator not found!")
        local autogendir = path.join(target:autogendir(), "rules", "verilator")
        local targetname = target:name()
        local cmakefile = path.join(autogendir, targetname .. ".cmake")

        local argv = {"--cc", "--make", "cmake", "--prefix", targetname, "--Mdir", path(autogendir)}
        local sourcefiles = sourcebatch.sourcefiles
        for _, sourcefile in ipairs(sourcefiles) do
            batchcmds:show_progress(opt.progress, "${color.build.target}compiling.verilator %s", path.filename(sourcefile))
        end
        table.join2(argv, sourcefiles)

        -- generate c++ sourcefiles
        batchcmds:mkdir(autogendir)
        batchcmds:vrunv(verilator, argv)
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(cmakefile))
        batchcmds:set_depcache(target:dependfile(cmakefile))
    end)

