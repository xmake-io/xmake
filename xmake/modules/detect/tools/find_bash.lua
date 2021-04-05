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
-- @author      xq114
-- @file        find_bash.lua
--

-- imports
import("lib.detect.find_tool")
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find bash
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local bash = find_bash()
-- local bash, version = find_bash({version = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find bash from git for windows
    if is_host("windows") then
        opt.paths = opt.paths or {}
        table.insert(opt.paths, "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\GitForWindows;InstallPath)\\bin")
    end

    -- find program
    local program = find_program(opt.program or "bash", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end

    -- ok?
    return program, version
end
