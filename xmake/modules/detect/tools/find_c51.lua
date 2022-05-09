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
-- @file        find_c51.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
local c51_module = import("detect.sdks.find_c51")

function _check(program)
    -- make temp source file
    local cfile = os.tmpfile() .. ".c"
    local objfile = os.tmpfile() .. ".obj"
    local lstfile = os.tmpfile() .. ".c"
    local tmpfile = "." .. os.tmpfile() .. ".un~"
    -- write test code
    io.writefile(cfile, "void main() {}")
    -- archive it
    os.runv(program, {cfile})
    -- remove files
    os.rm(cfile)
    os.rm(objfile)
    os.rm(lstfile)
    os.rm(tmpfile)
end
-- find c51
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local c51 = find_c51()
-- local c51, version = find_c51()
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}
    opt.check = opt.check or _check
    local program = find_program(opt.program or "c51.exe", opt)
    if not program then
        local c51_module = c51_module.find_c51()
        if c51_module then
            if c51_module.sdkdir_c51 then
                program = find_program(path.join(c51_module.sdkdir_c51, "bin", "c51.exe"), opt)
            end
            if not program and c51_module.sdkdir_a51 then
                program = find_program(path.join(c51_module.sdkdir_a51, "bin", "c51.exe"), opt)
            end
        end
    end
    return program, nil
end