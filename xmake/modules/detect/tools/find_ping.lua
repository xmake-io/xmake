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
-- @file        find_ping.lua
--

-- imports
import("lib.detect.find_program")

-- find ping
--
--
-- @param opt   the argument options
--
-- @return      program
--
function main(opt)

    -- init options
    opt       = opt or {}
    opt.check = opt.check or function (program)
        if is_host("windows") then
            os.run("%s -n 1 -w 500 127.0.0.1", program)
        elseif is_host("macosx") then
            os.run("%s -c 1 -t 1 127.0.0.1", program)
        else
            os.run("%s -c 1 -W 1 127.0.0.1", program)
        end
    end

    -- find program
    return find_program(opt.program or "ping", opt)
end
