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

rule("utils.bin2obj")
    set_extensions(".bin")
    add_orders("utils.bin2obj", "c++.build.modules.builder")
    on_buildcmd_file(function (target, batchcmds, sourcefile_bin, opt)
        import("rules.utils.bin2obj.utils", {alias = "bin2obj_utils", rootdir = os.programdir()})

        -- get zeroend (default: false)
        -- check file-level config first, then rule-level config
        local fileconfig = target:fileconfig(sourcefile_bin)
        local zeroend = (fileconfig and fileconfig.zeroend) or target:extraconf("rules", "utils.bin2obj", "zeroend") or false

        -- convert binary file to object file
        local objectfile = bin2obj_utils.generate_objectfile(target, batchcmds, sourcefile_bin, {
            progress = opt.progress,
            zeroend = zeroend
        })

        -- add deps
        batchcmds:add_depfiles(sourcefile_bin)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
