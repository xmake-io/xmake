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
-- @file        find_midl.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_program")
import("lib.detect.find_programver")

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
    opt.check   = opt.check or "/confirm"
    opt.command = opt.command or "/confirm"
    opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.%d+%.%d+)%s") end

    local envs = opt.envs
    if envs and envs.WindowsSdkDir and envs.WindowsSDKVersion then
        local toolchain = opt.toolchain
        local arch = toolchain and toolchain:arch() or config.arch()
        local bindir = path.join(envs.WindowsSdkDir, "bin", envs.WindowsSDKVersion, arch)
        if os.isdir(bindir) then
            opt.paths = opt.paths or {}
            table.insert(opt.paths, bindir)
        end
    end

    local program = find_program(opt.program or "midl", opt)

    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
