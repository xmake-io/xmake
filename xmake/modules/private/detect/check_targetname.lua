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
-- @file        check_targetname.lua
--

-- imports
import("core.project.project")
import("private.detect.find_similar_targetnames")

-- check if a target name is valid
--
-- @param targetname the target name to check for
-- @param opt        the argument options, e.g. {find_similar = false, max_similar = 5}
-- @return           target or nil, errors
--
-- @code
--
-- local target, errors = check_targetname("mytarget")
-- local target, errors = check_targetname("mytarget", {find_similar = false})
--
-- @endcode
--
function main(targetname, opt)
    opt = opt or {}

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
