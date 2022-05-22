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

rule("asn1c")
    set_extensions(".asn1")
    before_buildcmd_file(function (target, batchcmds, sourcefile_asn1, opt)

        -- get asn1c
        import("lib.detect.find_tool")
        local asn1c = assert(find_tool("asn1c"), "asn1c not found!")

        -- asn1 to *.c sourcefiles
        local sourcefile_dir = path.join(target:autogendir(), "rules", "asn1c")
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.asn1c %s", sourcefile_asn1)
        batchcmds:mkdir(sourcefile_dir)
        batchcmds:vrunv(asn1c.program, {path(sourcefile_asn1):absolute()}, {curdir = sourcefile_dir})

        -- compile *.c
        for _, sourcefile in ipairs(os.files(path.join(sourcefile_dir, "*.c|converter-*.c"))) do
            local objectfile = target:objectfile(sourcefile)
            batchcmds:compile(sourcefile, objectfile, {configs = {includedirs = sourcefile_dir}})
            table.insert(target:objectfiles(), objectfile)
        end

        -- add includedirs
        target:add("includedirs", sourcefile_dir)

        -- add deps
        batchcmds:add_depfiles(sourcefile_asn1)
        batchcmds:set_depcache(target:dependfile(sourcefile_asn1))
    end)
