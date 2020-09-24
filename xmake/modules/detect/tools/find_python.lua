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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_python.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.tools.find_python2")
import("detect.tools.find_python3")

-- find python
--
-- @param opt  the arguments, e.g. {version = true}
--
-- @return     program, version
--
-- @code
--
-- local python = find_python()
-- local python, version = find_python({version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find program
    local program = find_program(opt.program or "python", opt)
    if not program then
        program = find_python3() or find_python2()
    end

    -- find program version
    local version = nil
    if program and opt.version then
        opt.command = function ()
            local outs, errs = os.iorunv(program, {"--version"})
            return ((outs or "") .. (errs or "")):trim()
        end
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
