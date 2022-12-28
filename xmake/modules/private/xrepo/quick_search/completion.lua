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
-- @author      glcraft
-- @file        complete.lua
--

import("private.xrepo.quick_search.cache")

-- complete xrepo packages
function _xmake_package_complete(complete, opt)
    local candidates = {}
    local found = cache.find(complete)
    for _, candidate in ipairs(found) do
        table.insert(candidates, {value = candidate.name, description = candidate.data.description})
    end
    return candidates
end

function main(complete, opt)
    local prefix = ""

    -- if help menu, do nothing
    if opt.helpmenu then
        return {}
    end

    -- check prefix if present
    if complete:find("::", 1, true) then
        prefix = complete:sub(1, complete:find("::", 1, true) - 1)
        complete = complete:sub(complete:find("::", 1, true) + 2)
    end

    local packages

    -- complete xmake packages
    if prefix == "" or prefix == "xmake" then
        packages = _xmake_package_complete(complete, opt)
    end

    -- to prevent shell completion misunderstandings,
    -- we put back the prefix
    if packages and prefix ~= "" then
        for _, package in ipairs(packages) do
            package.value = prefix .. "::" .. package.value
        end
    end
    return packages or {}
end