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
-- @file        find_midl.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.sdks.find_vstudio")

-- find midl
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
-- local midl = find_midl()
-- @endcode
--
function main(opt)
    opt         = opt or {}
    -- @see https://github.com/xmake-io/xmake/issues/7192
    --
    -- "-?" prints the usage and exits with 0, 
    -- the old "/confirm" is unusable, it crashes with 0xC0000005
    opt.check   = opt.check or "-?"

    -- patch the host bin directory of sdk to path environment, midl.exe is executed on the host
    local envs = opt.envs
    if envs then
        local bindir = find_vstudio.get_winsdk_host_bindir(envs)
        if bindir then
            opt.paths = table.wrap(opt.paths)
            table.insert(opt.paths, bindir)
        end
    end

    local version = nil
    local program = find_program(opt.program or "midl", opt)
    if program and opt and opt.version then
        opt.command = opt.command or function () local _, info = os.iorunv(program, {"-?"}, {envs = opt.envs}); return info end
        opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.%d+%.%d+)%s") end
        version     = find_programver(program, opt)
    end
    return program, version
end
