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
-- @author      DawnMagnet
-- @file        find_oh51.lua
-- OBJECT TO HEX FILE CONVERTER OH51

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.sdks.find_c51")
import("lib.detect.find_tool")

function _check(program)
    local c51 = assert(find_tool("c51"), "c51 not found")
    local bl51 = assert(find_tool("bl51"), "bl51 not found")

    -- make temp source file
    local tmpdir = os.tmpfile() .. ".dir"
    os.mkdir(tmpdir)
    local cfile = path.join(tmpdir, "test.c")
    local objfile = path.join(tmpdir, "test.obj")
    local binfile = path.join(tmpdir, "test")

    -- write test code
    io.writefile(cfile, "void main() {}")

    -- archive it
    os.runv(c51.program, {"test.c"}, {curdir = tmpdir})
    os.runv(bl51.program, {objfile, "TO", binfile})
    os.runv(program, {binfile})

    -- remove files
    os.rmdir(tmpdir)
end
-- find oh51
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local oh51 = find_oh51()
-- local oh51, version = find_oh51()
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}
    opt.check = opt.check or _check
    local program = find_program(opt.program or "oh51.exe", opt)
    if not program then
        local c51 = find_c51()
        if c51 then
            if c51.sdkdir_c51 then
                program = find_program(path.join(c51.sdkdir_c51, "bin", "oh51.exe"), opt)
            end
            if not program and c51.sdkdir_a51 then
                program = find_program(path.join(c51.sdkdir_a51, "bin", "oh51.exe"), opt)
            end
        end
    end
    return program, nil
end