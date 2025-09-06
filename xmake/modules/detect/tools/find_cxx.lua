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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        find_cxx.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.tools.find_gcc")

-- find c++
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local cxx = find_cxx()
-- local cxx, version, hintname = find_cxx({program = "xcrun -sdk macosx c++", version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}

    local version = nil
    local program = find_program(opt.program or "c++", opt)
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- is clang++ or c++
    local is_clang = false
    if program then
        is_clang = find_gcc.check_clang(program, opt)
    end
    return program, version, (is_clang and "clangxx" or "cxx")
end
