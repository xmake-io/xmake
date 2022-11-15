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
-- @file        find_cl.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find cl
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local cl = find_cl()
--
-- @endcode
--
function main(opt)

    -- init options
    opt         = opt or {}
    opt.check   = opt.check or function (program)
        local ok = try { function () os.runv(program, {}, {envs = opt.envs}); return true end }
        if not ok then
            -- @see https://github.com/xmake-io/xmake/issues/3057
            local objectfile = os.tmpfile() .. ".obj"
            local sourcefile = os.tmpfile() .. ".c"
            io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
            os.runv(program, {"-c", "-Fo" .. objectfile, sourcefile}, {envs = opt.envs})
            os.rm(objectfile)
            os.rm(sourcefile)
        end
    end

    -- find program
    local program = find_program(opt.program or "cl.exe", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        opt.command = opt.command or function () local _, info = os.iorunv(program, {}, {envs = opt.envs}); return info end
        opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.?%d*%.?%d*.-)%s") end
        version     = find_programver(program, opt)
    end
    return program, version
end

