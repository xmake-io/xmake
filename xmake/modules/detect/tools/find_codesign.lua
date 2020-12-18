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
-- @file        find_codesign.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")

-- find codesign
--
-- @param opt  the arguments, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local codesign = find_codesign()
-- local codesign, version = find_codesign({version = true})
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
    opt.check = function (program)
        os.runv(program, {"-d", "/bin/echo"})
    end

    -- find program
    return find_program(opt.program or "codesign", opt)
end
