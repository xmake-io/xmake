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

rule("iverilog.binary")
    set_extensions(".v", ".vhd")
    on_load(function (target)
        target:set("kind", "binary")
        if not target:get("extension") then
            target:set("extension", ".vvp")
        end
    end)

    on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
    end)

    on_linkcmd(function (target, batchcmds, opt)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local iverilog = assert(toolchain:config("iverilog"), "iverilog not found!")

        -- compile wave file
        local targetfile = target:targetfile()
        local targetdir = path.directory(targetfile)
        local argv = {"-o", targetfile}
        local sourcebatch = target:sourcebatches()["iverilog.binary"]
        local sourcefiles = sourcebatch.sourcefiles
        table.join2(argv, sourcefiles)
        batchcmds:show_progress(opt.progress, "${color.build.target}linking.iverilog %s", path.filename(targetfile))
        batchcmds:mkdir(targetdir)
        batchcmds:vrunv(iverilog, argv)
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(targetfile))
        batchcmds:set_depcache(target:dependfile(targetfile))
    end)

    on_run(function (target)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local vvp = assert(toolchain:config("vvp"), "vvp not found!")

        os.execv(vvp, {"-n", target:targetfile(), "-lxt2"})
    end)
