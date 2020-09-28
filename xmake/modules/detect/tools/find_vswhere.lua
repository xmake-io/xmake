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
-- @file        find_vswhere.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find vswhere
--
-- @param opt   the argument options, e.g. {version = true, program = "c:\xxx\vswhere.exe"}
--
-- @return      program, version
--
-- @code
--
-- local vswhere = find_vswhere()
-- local vswhere, version = find_vswhere({version = true})
-- local vswhere, version = find_vswhere({version = true, program = "c:\xxx\vswhere.exe"})
--
-- @endcode
--
function main(opt)

    -- not on windows?
    if not is_host("windows") then
        return
    end

    -- init options
    opt = opt or {}

    -- find program
    opt.check   = opt.check or "-?"
    opt.command = opt.command or "-?"
    opt.paths   = opt.paths or
    {
        "$(env ProgramFiles%(x86%))\\Microsoft Visual Studio\\Installer",
        "$(env ProgramFiles)\\Microsoft Visual Studio\\Installer"
    }
    local program = find_program(opt.program or "vswhere.exe", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
