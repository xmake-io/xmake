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
-- @file        find_hdiutil.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find hdiutil
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local hdiutil = find_hdiutil()
-- local hdiutil, version = find_hdiutil({version = true})
--
-- @endcode
--
function main(opt)

    -- only for macosx
    if not is_host("macosx") then
        return
    end

    -- init options
    opt = opt or {}
    opt.check = opt.check or "help"

    -- find program
    local program = find_program(opt.program or "hdiutil", opt)

    -- find program version
    local version = nil
    if program and opt and opt.version then
        opt.command = opt.command or "info"
        opt.parse = opt.parse or function (output)
            -- extract version from "framework : 671.140.2" or "driver : 671.140.2"
            return output:match("framework%s*:%s*(%d+%.%d+%.%d+)") or output:match("driver%s*:%s*(%d+%.%d+%.%d+)")
        end
        version = find_programver(program, opt)
    end
    return program, version
end

