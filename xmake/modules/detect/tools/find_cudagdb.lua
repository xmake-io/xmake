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
-- @author      OpportunityLiu
-- @file        find_cudagdb.lua
--

-- imports
import("private.detect.find_cudatool")

-- find cudagdb
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local cudagdb = find_cudagdb()
-- local cudagdb, version = find_cudagdb({program = "cuda-gdb", version = true})
--
-- @endcode
--
function main(opt)
    return find_cudatool("cuda-gdb", "(%d+%.?%d*%.?%d*.-)%s+release", opt)
end
