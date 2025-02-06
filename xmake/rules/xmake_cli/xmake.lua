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

rule("xmake.cli")
    set_extensions(".lua")

    on_load(function (target)
        target:set("kind", "binary")
        assert(target:pkg("libxmake"), 'please add_packages("libxmake") to target(%s) first!', target:name())

        local headerdir = path.join(target:autogendir(), "rules", "xmake.cli", "include")
        if not os.isdir(headerdir) then
            os.mkdir(headerdir)
        end
        target:add("includedirs", headerdir)
    end)

    before_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        import("private.core.base.match_copyfiles")
        local sourcefiles = sourcebatch.sourcefiles
        local archivefile = path.join(target:autogendir(), "rules", "xmake.cli", "luafiles.xmz")
        local dependfile = archivefile .. ".d"
        batchcmds:show_progress(opt.progress, "${color.build.target}archiving.luafiles %s", target:name())

        local luadir = path.join(target:autogendir(), "rules", "xmake.cli", "luafiles")
        local argv = {"lua", "cli.archive", "-r", "-w", path(luadir), "-o", path(archivefile)}
        local srcfiles, dstfiles = match_copyfiles(target, "files", path.join(luadir, "modules"))
        for idx, srcfile in ipairs(srcfiles) do
            if srcfile:endswith(".lua") then
                local dstfile = dstfiles[idx]
                batchcmds:cp(srcfile, dstfile)
                table.insert(argv, path(dstfile))
            end
        end
        batchcmds:vrunv(os.programfile(), argv, {envs = {XMAKE_SKIP_HISTORY = "y"}})

        local headerdir = path.join(target:autogendir(), "rules", "xmake.cli", "include")
        local headerfile = path.join(headerdir, "luafiles.xmz.h")
        target:add("includedirs", headerdir)
        argv = {"lua", "private.utils.bin2c", "--nozeroend", "-i", path(archivefile), "-o", path(headerfile)}
        batchcmds:vrunv(os.programfile(), argv, {envs = {XMAKE_SKIP_HISTORY = "y"}})

        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(dependfile))
        batchcmds:set_depcache(dependfile)
    end)
