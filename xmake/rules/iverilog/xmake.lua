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

rule("iverilog.wave")
    set_extensions(".v", ".vhd")
    on_load(function (target)
        target:set("kind", "binary")
        if not target:get("extension") then
            target:set("extension", ".vcd")
        end
    end)

    on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local iverilog = assert(toolchain:config("iverilog"), "iverilog not found!")

        -- compile wave file
        local targetfile = target:targetfile()
        local targetdir = path.directory(targetfile)
        local vvpfile = path.join(targetdir, path.basename(targetfile) .. ".vvp")
        local argv = {"-o", vvpfile}
        local sourcefiles = sourcebatch.sourcefiles
        for _, sourcefile in ipairs(sourcefiles) do
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.iverilog %s", path.filename(sourcefile))
            table.insert(argv, path(sourcefile))
            batchcmds:add_depfiles(sourcefile)
        end
        batchcmds:mkdir(targetdir)
        batchcmds:vrunv(iverilog, argv)
        batchcmds:set_depmtime(os.mtime(vvpfile))
        batchcmds:set_depcache(target:dependfile(vvpfile))
    end)

    on_linkcmd(function (target, batchcmds, opt)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local vvp = assert(toolchain:config("vvp"), "vvp not found!")

        -- generate wave.lxt
        local targetfile = target:targetfile()
        local targetdir = path.directory(targetfile)
        local vvpfile = path.join(targetdir, path.basename(targetfile) .. ".vvp")
        batchcmds:show_progress(opt.progress, "${color.build.target}linking.iverilog %s", path.filename(targetfile))
        batchcmds:vrunv(vvp, {"-n", vvpfile, "-lxt2"})
        batchcmds:add_depfiles(vvpfile)
        batchcmds:set_depmtime(os.mtime(targetfile))
        batchcmds:set_depcache(target:dependfile(targetfile))
    end)
