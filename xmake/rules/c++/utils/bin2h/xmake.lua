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

rule("c++.utils.bin2h")
    set_extensions(".bin")
    on_load(function (function (target)
        local headerdir = path.join(target:autogendir(), "rules", "c++", "bin2h")
        if not os.isfile(headerdir) then
            os.mkdir(headerdir)
        end
        target:add("includedirs", headerdir)
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_bin, opt)

        -- get header file
        local headerdir = path.join(target:autogendir(), "rules", "c++", "bin2h")
        local headerfile = path.join(headerdir, path.basename(sourcefile_bin) .. ".h")

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.header %s", sourcefile_bin)
        batchcmds:mkdir(headerdir)

        -- TODO

        -- add deps
        batchcmds:add_depfiles(sourcefile_bin)
        batchcmds:set_depmtime(os.mtime(headerfile))
        batchcmds:set_depcache(target:dependfile(headerfile))
    end)

