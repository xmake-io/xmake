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

rule("utils.bin2c")
    set_extensions(".bin")
    on_load(function (target)
        local headerdir = path.join(target:autogendir(), "rules", "utils", "bin2c")
        if not os.isdir(headerdir) then
            os.mkdir(headerdir)
        end
        target:add("includedirs", headerdir)
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_bin, opt)

        -- get header file
        local headerdir = path.join(target:autogendir(), "rules", "utils", "bin2c")
        local headerfile = path.join(headerdir, path.filename(sourcefile_bin) .. ".h")
        target:add("includedirs", headerdir)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.bin2c %s", sourcefile_bin)
        batchcmds:mkdir(headerdir)
        local argv = {"lua", "private.utils.bin2c", "-i", path(sourcefile_bin), "-o", path(headerfile)}
        local linewidth = target:extraconf("rules", "utils.bin2c", "linewidth")
        if linewidth then
            table.insert(argv, "-w")
            table.insert(argv, tostring(linewidth))
        end
        batchcmds:vrunv(os.programfile(), argv, {envs = {XMAKE_SKIP_HISTORY = "y"}})

        -- add deps
        batchcmds:add_depfiles(sourcefile_bin)
        batchcmds:set_depmtime(os.mtime(headerfile))
        batchcmds:set_depcache(target:dependfile(headerfile))
    end)

