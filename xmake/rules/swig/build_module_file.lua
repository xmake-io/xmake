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
-- @file        build_module_file.lua
--

-- imports
import("lib.detect.find_tool")

function main(target, batchcmds, sourcefile, opt)

    -- get module type
    opt = opt or {}
    local moduletype
    local fileconfig = target:fileconfig(sourcefile)
    if fileconfig then
        moduletype = fileconfig.moduletype
    end
    assert(moduletype, "%s: unknown swig module type, please use `add_files(\"foo.c\", {moduletype = \"python\"})` to set it!", sourcefile)

    -- get swig
    local swig = assert(find_tool("swig"), "swig not found!")
    local sourcefile_cx = path.join(target:autogendir(), "rules", "swig", path.basename(sourcefile) .. (opt.sourcekind == "cxx" and ".cpp" or ".c"))

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    local argv = {"-" .. moduletype, "-o", sourcefile_cx}
    if opt.sourcekind == "cxx" then
        table.insert(argv, "-c++")
    end
    table.insert(argv, sourcefile)
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.swig.%s %s", moduletype, sourcefile)
    batchcmds:mkdir(path.directory(sourcefile_cx))
    batchcmds:vrunv(swig.program, argv)
    batchcmds:compile(sourcefile_cx, objectfile)

    -- add deps
    batchcmds:add_depfiles(sourcefile)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end
