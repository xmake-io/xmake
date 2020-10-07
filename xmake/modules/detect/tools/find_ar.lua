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
-- @file        find_ar.lua
--

-- imports
import("lib.detect.find_program")

-- check
function _check(program)

    -- make a stub object file
    local libraryfile = os.tmpfile() .. ".a"
    local objectfile  = os.tmpfile() .. ".o"
    io.writefile(objectfile, "")

    -- archive it
    os.runv(program, {"-cr", libraryfile, objectfile})

    -- remove files
    os.rm(objectfile)
    os.rm(libraryfile)
end

-- find ar
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local ar = find_ar()
-- local ar, version = find_ar({program = "xcrun -sdk macosx g++", version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt       = opt or {}
    opt.check = opt.check or _check

    -- find program
    return find_program(opt.program or "ar", opt)
end
