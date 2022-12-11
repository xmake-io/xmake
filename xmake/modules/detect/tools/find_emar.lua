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
-- @file        find_emar.lua
--

-- imports
import("core.tool.compiler")
import("lib.detect.find_program")
import("detect.sdks.find_emsdk")

-- check
function _check(program)

    -- make an stub source file
    local libraryfile   = os.tmpfile() .. ".a"
    local objectfile    = os.tmpfile() .. ".o"
    local sourcefile    = os.tmpfile() .. ".c"
    io.writefile(sourcefile, "int test(void)\n{return 0;}")

    -- compile it
    compiler.compile(sourcefile, objectfile)

    -- archive it
    os.runv(program, {"-cr", libraryfile, objectfile})

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
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
-- local ar = find_emar()
-- local ar, version = find_emar({program = "xcrun -sdk macosx g++", version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt       = opt or {}
    opt.check = opt.check or _check

    -- init the search directories
    local emsdk = find_emsdk()
    if emsdk and emsdk.emscripten then
        local paths = {}
        table.insert(paths, emsdk.emscripten)
        opt.paths = paths
    end

    -- find program
    return find_program(opt.program or (is_host("windows") and "emar.bat" or "emar"), opt)
end
