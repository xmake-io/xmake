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
-- @file        find_asn1c.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find asn1c
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local asn1c = find_asn1c()
-- local asn1c, version = find_asn1c({version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt         = opt or {}
    opt.check   = opt.check or "-v"
    opt.command = opt.command or "-v"

    -- find program
    local program = find_program(opt.program or "asn1c", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
