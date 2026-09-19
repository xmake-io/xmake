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
    -- "-?" prints the usage and exits with 0, 
    -- the old "/confirm" is unusable, it crashes with 0xC0000005
    opt.check   = opt.check or "-?"

    -- @see https://github.com/xmake-io/xmake/issues/7192
    --
    -- However, norunfile skips the run check, so a midl that cannot run on the 
    -- host is accepted silently, e.g. an arm64 midl.exe when cross-compiling on
    -- a x64 host, then it only fails later on generating the idl files,
    --
    --     error: cannot runv(...\Windows Kits\10\bin\10.0.26100.0\arm64\midl ...)
    --
    -- "-?" is a usable check, so enable the run check again.
    opt.norunfile = false

    local envs = opt.envs
    if envs and envs.WindowsSdkDir and envs.WindowsSDKVersion then
        local toolchain = opt.toolchain
        local arch = toolchain and toolchain:arch() or config.arch()
        local bindir = path.join(envs.WindowsSdkDir, "bin", envs.WindowsSDKVersion, arch)
        if os.isdir(bindir) then
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
