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
-- @file        find_strip.lua
--

-- imports
import("core.tool.compiler")
import("lib.detect.find_program")

-- check strip of xcode
function _check_strip_of_xcode(program)

    -- make an stub source file
    local objectfile    = os.tmpfile() .. ".o"
    local sourcefile    = os.tmpfile() .. ".c"
    io.writefile(sourcefile, "int test(void)\n{return 0;}")

    -- compile it
    compiler.compile(sourcefile, objectfile)

    -- archive it
    os.runv(program, {"-S", objectfile})

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
end

-- find strip
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local strip = find_strip()
-- local strip, version = find_strip({program = "xcrun -sdk macosx strip", version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- attempt to find gnu strip first with `--version`
    local program = find_program(opt.program or "strip", opt)
    if not program then
        -- find strip of xcode without `--version`
        if is_plat("macosx", "iphoneos", "watchos") or is_host("macosx") then
            opt.force = true
            opt.check = _check_strip_of_xcode
            program = find_program(opt.program or "strip", opt)
        end
    end

    -- find program version
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
