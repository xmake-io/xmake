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
import("private.detect.check_targetname")

-- check if the given target names are valid
--
-- @param targetnames a single target name or a list of target names to check for
-- @param opt         the argument options, e.g. {find_similar = false, max_similar = 5}
-- @return            targets or nil, errors
--
-- @code
--
-- local targets, errors = check_targetnames("mytarget")
-- local targets, errors = check_targetnames({"target1", "target2"})
--
-- @endcode
--
function main(targetnames, opt)
    local targets = {}
    for _, targetname in ipairs(table.wrap(targetnames)) do
        local target, errors = check_targetname(targetname, opt)
        if not target then
            return nil, errors
        end
        table.insert(targets, target)
    end
    return targets
end
