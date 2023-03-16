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
-- @file        find_tclsh.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find tclsh
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local tclsh = find_tclsh()
-- local tclsh, version = find_tclsh({program = "tclsh", version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    opt.check   = opt.check or function (program)
        local infile = os.tmpfile()
        local outfile = os.tmpfile()
        io.writefile(infile, "puts hello\n")
        local outdata = os.iorunv(program, {infile})
        assert(outdata == "hello\n")
        os.rm(infile)
        os.rm(outfile)
    end
    return find_program(opt.program or "tclsh", opt)
end
