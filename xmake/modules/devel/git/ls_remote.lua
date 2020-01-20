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
-- @file        ls_remote.lua
--

-- imports
import("main", { alias = "git" })

-- ls_remote to given branch, tag or commit
--
-- @param reftype   the reference type, "tags", "heads" and "refs"
-- @param url       the remote url, optional
--
-- @return          the tags, heads or refs
--
-- @code
--
-- import("devel.git")
-- 
-- local tags   = git.ls_remote("tags", url)
-- local heads  = git.ls_remote("heads", url)
-- local refs   = git.ls_remote("refs")
--
-- @endcode
--
function main(...)

    local params = table.pack(...)

    if params.n <= 2 and (params[1] == nil or type(params[1]) == "string") and (params[2] == nil or type(params[2]) == "string") then
        -- init reference type
        local reftype = params[1] or "refs"
        local url = params[2] or "."

        params = { { [reftype] = true }, url, n = 2 }
    end

    -- get refs
    return git().ls_remote(table.unpack(params, 1, params.n))
end
