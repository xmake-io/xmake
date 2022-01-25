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
-- @file        find_cc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find c++
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local cc = find_cc()
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find program
    local program = find_program(opt.program or "cc", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- is clang++ or c++
    local is_clang = false
    if program then
        local versioninfo = os.iorunv(program, {"--version"})
        if versioninfo and versioninfo:find("clang", 1, true) then
            is_clang = true
        end
    end
    return program, version, (is_clang and "clang" or "cc")
end
