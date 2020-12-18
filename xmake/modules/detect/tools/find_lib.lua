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
-- @file        find_lib.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("lib.detect.find_tool")

-- find lib
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local lib = find_lib()
--
-- @endcode
--
function main(opt)

    -- init version info first
    local verinfo = nil

    -- init options
    opt       = opt or {}
    opt.check = opt.check or function (program)

        -- make an stub source file
        local libraryfile = os.tmpfile() .. ".lib"
        local objectfile  = os.tmpfile() .. ".obj"
        local sourcefile  = os.tmpfile() .. ".c"
        io.writefile(sourcefile, "int test(void)\n{return 0;}")

        -- check it
        local cl = assert(find_tool("cl", {envs = opt.envs}))
        local link = assert(find_tool("link", {envs = opt.envs}))
        os.runv(cl.program, {"-c", "-Fo" .. objectfile, sourcefile}, {envs = opt.envs})
        os.runv(link.program, {"-lib", "-out:" .. libraryfile, objectfile}, {envs = opt.envs})
        verinfo = os.iorunv(program, {"-list", libraryfile}, {envs = opt.envs})

        -- remove files
        os.rm(objectfile)
        os.rm(sourcefile)
        os.rm(libraryfile)
    end
    opt.command = opt.command or function () return verinfo end
    opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.?%d*%.?%d*.-)%s") end

    -- find program
    local program = find_program(opt.program or "lib.exe", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end

