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
-- @file        find_rc.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find rc
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local rc = find_rc()
--
-- @endcode
--
function main(opt)

    -- not on windows?
    if not is_host("windows") then
        return
    end

    -- init options
    opt         = opt or {}
    opt.check   = opt.check or "-?"
    opt.command = opt.command or "-?"
    opt.parse   = opt.parse or function (output) return output:match("Version (%d+%.?%d*%.?%d*.-)%s") end

    -- fix rc.exe missing issues
    --
    -- @see https://github.com/xmake-io/xmake/issues/225
    -- https://stackoverflow.com/questions/43847542/rc-exe-no-longer-found-in-vs-2015-command-prompt/45319119
    --
    -- patch sdk bin directory to path environment
    --
    -- e.g. C:\Program Files (x86)\Windows Kits\10\bin\10.0.17134.0\x64
    --
    local envs = opt.envs
    if envs and envs.WindowsSdkDir and envs.WindowsSDKVersion then
        local bindir = path.join(envs.WindowsSdkDir, "bin", envs.WindowsSDKVersion, arch)
        if os.isdir(bindir) then
            opt.paths = opt.paths or {}
            table.insert(opt.paths, bindir)
        end
    end

    -- find program
    local program = find_program(opt.program or "rc.exe", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end

