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
-- @file        find_llvm_rc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find llvm-rc
--
-- @param opt   the argument options, e.g. {version = true, program = "c:\xxx\llvm_rc.exe"}
--
-- @return      program, version
--
-- @code
--
-- local llvm_rc = find_llvm_rc()
-- local llvm_rc, version = find_llvm_rc({version = true})
-- local llvm_rc, version = find_llvm_rc({version = true, program = "c:\xxx\llvm_rc.exe"})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find program
    opt.check = opt.check or "/?"
    return find_program(opt.program or "llvm-rc", opt)
end
