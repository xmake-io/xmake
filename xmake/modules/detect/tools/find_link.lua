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
-- @file        find_link.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("lib.detect.find_tool")

-- find link
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local link = find_link()
--
-- @endcode
--
function main(opt)

    -- init version info first
    local version = nil
    local verinfo = nil

    -- init options
    opt = opt or {}
    opt.check = opt.check or function (program)
        local toolchain = opt.toolchain
        if toolchain and toolchain:name() == "masm32" then
            -- if this link.exe is from masm32 sdk, we just pass it fastly
            -- because it does not contain cl.exe
            --
            -- TODO maybe we can use ml to improve it
        else
            local cl = assert(find_tool("cl", {envs = opt.envs}))

            -- make an stub source file
            local binaryfile = os.tmpfile() .. ".exe"
            local objectfile = os.tmpfile() .. ".obj"
            local sourcefile = os.tmpfile() .. ".c"

            -- compile sourcefile first
            io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
            os.runv(cl.program, {"-c", "-Fo" .. objectfile, sourcefile}, {envs = opt.envs})

            -- do link
            verinfo = os.iorunv(program, {"-lib", "-out:" .. binaryfile, objectfile}, {envs = opt.envs})

            -- remove files
            os.rm(objectfile)
            os.rm(sourcefile)
            os.rm(binaryfile)
        end
    end
    opt.command = opt.command or function () return verinfo end
    opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.?%d*%.?%d*.-)%s") end

    -- find program
    local program = find_program(opt.program or "link.exe", opt)

    -- find program version
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end

