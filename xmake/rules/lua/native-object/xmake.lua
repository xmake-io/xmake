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
-- @author      Wu, Zhenyu
-- @file        xmake.lua
--

-- usage:
--
-- target("foo")
-- do
--     add_rules("luarocks.module", "lua-native-object", "c")
--     add_files("*.nobj.lua")
-- end
rule("lua.native-object")
    set_extensions(".nobj.lua")
    before_buildcmd_file(function(target, batchcmds, sourcefile, opt)
        -- get c source file for lua-native-object
        local dirname = path.join(target:autogendir(), "rules", "lua-native-object")
        local sourcefile_c = path.join(dirname, path.basename(sourcefile) .. ".c")

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_c)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.nobj.lua %s", sourcefile)
        batchcmds:mkdir(path.directory(sourcefile_c))
        batchcmds:vrunv("native_objects.lua",
            { "-outpath", path(dirname), "-gen", "lua", path(sourcefile) })
        -- remember to add_rules("c") if you need
        batchcmds:compile(sourcefile_c, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
