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
-- @file        cxxbridge.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

function main(target, batchcmds, sourcefile, opt)
    local cxxbridge = assert(find_tool("cxxbridge"), "cxxbridge not found, please run `cargo install cxxbridge-cmd` to install it first!")

    -- get c/c++ source file for cxxbridge
    local headerfile = path.join(target:autogendir(), "rules", "cxxbridge", path.basename(sourcefile) .. ".rs.h")
    local sourcefile_cx = path.join(target:autogendir(), "rules", "cxxbridge", path.basename(sourcefile) .. ".rs.cc")

    -- add includedirs
    target:add("includedirs", path.directory(headerfile))

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.cxxbridge %s", sourcefile)
    batchcmds:mkdir(path.directory(sourcefile_cx))
    batchcmds:vexecv(cxxbridge.program, {sourcefile}, {stdout = sourcefile_cx})
    batchcmds:vexecv(cxxbridge.program, {sourcefile, "--header"}, {stdout = headerfile})
    batchcmds:compile(sourcefile_cx, objectfile)

    -- add deps
    batchcmds:add_depfiles(sourcefile)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end
