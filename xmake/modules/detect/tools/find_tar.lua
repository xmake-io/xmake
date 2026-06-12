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
-- @file        find_tar.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find tar
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local tar = find_tar()
-- local tar, version = find_tar({version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    opt.check = opt.check or function (program)
        local ok = try { function () os.runv(program, {"--version"}, {envs = opt.envs, shell = opt.shell}) end }
        if not ok then
            -- some tar do not support `--version`, so we fall back to creating a temporary archive to check it
            local tmpdir = os.tmpfile() .. ".dir"
            os.mkdir(tmpdir)
            io.writefile(path.join(tmpdir, "test.txt"), "")
            os.runv(program, {"-cf", "test.tar", "test.txt"}, {curdir = tmpdir, envs = opt.envs, shell = opt.shell})
            os.rm(tmpdir)
        end
    end

    -- find program
    local program = find_program(opt.program or "tar", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
