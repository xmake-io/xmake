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
-- @file        find_lldb.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find lldb
--
-- @param opt   the argument options, e.g. {version = true, program="/usr/bin/lldb"}
--
-- @return      program, version
--
-- @code
--
-- local lldb = find_lldb()
-- local lldb, version = find_lldb({version = true})
-- local lldb, version = find_lldb({version = true, program = "/usr/bin/lldb"})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find program
    local program = find_program(opt.program or "lldb", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
