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
-- @file        apply.lua
--

-- imports
import("main", { alias = "git" })

-- apply remote commits
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
-- 
-- git.apply("xxx.patch")
-- git.apply("xxx.diff")
--
-- @endcode
--
function main(...)

    local params = table.pack(...)
    for i = 1, params.n do
        local p = params[i]
        if type(p) == "string" then
            params[i] = path.absolute(p)
        end
    end

    return git().apply({reject = true}, table.unpack(params, 1, params.n))
end
