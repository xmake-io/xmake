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

function _check(program)
    import("detect.tools.find_c51")
    import("detect.tools.find_bl51")

    -- make temp source file
    local c51 = assert(find_c51())
    local bl51 = assert(find_bl51())
    local temp_prefix = os.tmpfile()
    local cfile = temp_prefix .. ".c"
    local objfile = temp_prefix .. ".obj"
    local lstfile = temp_prefix .. ".lst"
    local tmpfile = "." .. temp_prefix .. ".un~"
    local binfile = temp_prefix .. ""
    local m51file = temp_prefix .. ".m51"
    local hexfile = temp_prefix .. ".hex"
    -- write test code
    io.writefile(cfile, "void main() {}")
    -- archive it
    os.runv(c51, {cfile})
    os.runv(bl51, {objfile, "TO", binfile})
    os.runv(program, {binfile})
    -- remove files
    os.rm(cfile)
    os.rm(objfile)
    os.rm(lstfile)
    os.rm(tmpfile)
    os.rm(binfile)
    os.rm(m51file)
    os.rm(hexfile)
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