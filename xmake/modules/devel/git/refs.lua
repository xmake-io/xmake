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
-- @file        refs.lua
--

-- imports
import("core.base.option")
import("ls_remote")

-- get all refs from url, contains tags and branchs
--
-- @param url       the remote url, optional
--
-- @return          the tags, branches
--
-- @code
--
-- import("devel.git")
--
-- local tags, branches = git.refs(url)
--
-- @endcode
--
function main(url)

    -- get refs
    local refs = ls_remote("refs", url)
    if not refs or #refs == 0 then
        return {}, {}
    end

    -- get tags and branches
    local tags = {}
    local branches = {}
    for _, ref in ipairs(refs) do
        if ref:startswith("tags/") then
            table.insert(tags, ref:sub(6))
        elseif ref:startswith("heads/") then
            table.insert(branches, ref:sub(7))
        end
    end

    -- ok
    return tags, branches
end
