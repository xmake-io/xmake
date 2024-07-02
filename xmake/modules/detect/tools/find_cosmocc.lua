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
-- @file        find_cosmocc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find cosmocc
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local cosmocc = find_cosmocc()
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    opt.shell = true
    opt.envs  = {PATH = os.getenv("PATH")}
    local program = find_program(opt.program or "cosmocc", opt)
    if program and is_host("windows") then
        program = program:gsub("\\", "/")
    end
    local version = nil
    if program and opt and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
