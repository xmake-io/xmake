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
-- @file        check_targetnames.lua
--

-- imports
import("core.project.project")
import("private.detect.find_similar_targetnames")

-- check if a single target name is valid
function _check_targetname(targetname, opt)
    local target = project.target(targetname)
    if target then
        return target
    end

    local errors = "'" .. targetname .. "' is not a valid target name for this project."
    if opt.find_similar ~= false then
        local matching_targetnames = find_similar_targetnames(targetname)
        if #matching_targetnames > 0 then
            local max_index = math.min(#matching_targetnames, opt.max_similar or 14)
            errors = errors .. "\nValid target names closest to input:\n - "
                    .. table.concat(matching_targetnames, '\n - ', 1, max_index)
        end
    end
    return nil, errors
end

-- check if the given target names are valid
--
-- it accepts either a single target name or a list of target names. for a single
-- target name (string), it returns the single matching target; for a list, it
-- returns the matching targets as a list.
--
-- @param targetnames a single target name or a list of target names to check for
-- @param opt         the argument options, e.g. {find_similar = false, max_similar = 5}
-- @return            target(s) or nil, errors
--
-- @code
--
-- local target  = assert(check_targetnames("mytarget"))
-- local targets = assert(check_targetnames({"target1", "target2"}))
--
-- @endcode
--
function main(targetnames, opt)
    opt = opt or {}
    local targets = {}
    for _, targetname in ipairs(table.wrap(targetnames)) do
        local target, errors = _check_targetname(targetname, opt)
        if not target then
            return nil, errors
        end
        table.insert(targets, target)
    end
    -- unwrap to a single target if a single target name is given
    if type(targetnames) ~= "table" then
        return targets[1]
    end
    return targets
end
