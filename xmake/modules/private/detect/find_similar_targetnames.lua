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
-- @author      Shiffted
-- @file        find_similar_targetnames.lua
--

-- imports
import("core.project.project")

-- find targets with a similar name
--
-- @param targetname the target name to check against
-- @return           table of matching target names
--
-- @code
--
-- local tool = find_similar_targetnames("mytarget")
--
-- @endcode
--
function main(targetname)
    local targetname_lower = targetname:lower()
    local matching_targetnames = {}
    local matching_levenshtein = {}

    for _, target in ipairs(project.ordertargets()) do
        local name = target:name()
        if name:lower():find(targetname_lower, 1, true) then
            table.insert(matching_targetnames, name)
        else
            local distance = targetname:levenshtein(name, {sub = 2})
            if distance < 5 then
                matching_levenshtein[name] = distance
            end
        end
    end

    table.sort(matching_targetnames, function(a, b)
        if #a == #b then
            return a < b
        end
        return #a < #b
    end)

    local levenshtein_keys = table.keys(matching_levenshtein)
    table.sort(levenshtein_keys, function(a, b)
        local a_distance = matching_levenshtein[a]
        local b_distance = matching_levenshtein[b]
        if a_distance == b_distance then
            return a < b
        end
        return a_distance < b_distance
    end)

    table.join2(matching_targetnames, levenshtein_keys)
    return matching_targetnames
end
