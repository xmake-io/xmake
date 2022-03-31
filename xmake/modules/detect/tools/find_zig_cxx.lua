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
-- @file        find_zig_cxx.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find zig_cxx
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local zig_cxx = find_zig_cxx()
-- local zig_cxx, version, hintname = find_zig_cxx({program = "zig c++", version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    local program = find_program(opt.program or "zig c++", opt)
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
