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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

rule("utils.bin2c")
    set_extensions(".bin")
    add_orders("utils.bin2c", "c++.build.modules.builder")
    on_load(function (target)
        local headerdir = path.join(target:autogendir(), "rules", "utils", "bin2c")
        if not os.isdir(headerdir) then
            os.mkdir(headerdir)
        end
        target:add("includedirs", headerdir)
    end)
    on_preparecmd_file(function (target, batchcmds, sourcefile_bin, opt)
        import("rules.utils.bin2c.utils", {alias = "bin2c_utils", rootdir = os.programdir()})

        -- generate header file
        local headerfile = bin2c_utils.generate_headerfile(target, batchcmds, sourcefile_bin, {
            progress = opt.progress
        })

        -- add deps
        batchcmds:add_depfiles(sourcefile_bin)
        batchcmds:set_depmtime(os.mtime(headerfile))
        batchcmds:set_depcache(target:dependfile(headerfile))
    end)

