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
--     add_rules("lua.module", "lua.native-objects", "c")
--     add_files("*.nobj.lua")
-- end
rule("lua.native-objects")
    set_extensions(".nobj.lua")
    add_deps("c")
    before_buildcmd_file(function(target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")
        -- get c source file for lua.native-objects
        local dirname = path.join(target:autogendir(), "rules", "lua", "native-objects")
        local sourcefile_c = path.join(dirname, path.basename(sourcefile) .. ".c")

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_c)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.nobj.lua %s", sourcefile)
        batchcmds:mkdir(path.directory(sourcefile_c))
        local native_objects = find_tool("native_objects")
        assert(native_objects, "native_objects not found! please `luarocks install luanativeobjects`.")
        batchcmds:vrunv(native_objects.program,
            { "-outpath", path(dirname), "-gen", "lua", path(sourcefile) })
        batchcmds:compile(sourcefile_c, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
