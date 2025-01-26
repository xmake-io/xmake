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
-- @file        find_ilinkarm.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("detect.sdks.find_iarsdk")

-- find ilinkarm
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local ilinkarm = find_ilinkarm()
-- local ilinkarm, version = find_ilinkarm({program = "ilinkarm", version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}

    -- find program
    local program = find_program(opt.program or "ilinkarm.exe", opt)
    if not program then
        local iarsdk = find_iarsdk()
        if iarsdk and iarsdk.sdkdir then
            program = find_program(path.join(iarsdk.sdkdir, "bin", "ilinkarm.exe"), opt)
        end
    end

    -- find program version
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end
    return program, version
end
