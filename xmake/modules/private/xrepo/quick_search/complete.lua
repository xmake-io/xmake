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

function main(complete, opt)
    local packages = cache.get()
    local candidates = {}
    for _, package in ipairs(packages) do
        if package.name:startswith(complete) then
            table.insert(candidates, { value = package.name, description = package.description })
        end
    end
    return candidates
end