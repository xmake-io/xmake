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
-- @file        get_requires.lua
--

-- imports
import("core.base.option")
import("core.project.project")

-- get requires and extra config
function main(requires)

    -- init requires
    local requires_extra = nil
    if not requires then
        requires, requires_extra = project.requires_str()
    end
    if not requires or #requires == 0 then
        return
    end

    -- get extra info
    local extra =  option.get("extra")
    local extrainfo = nil
    if extra then
        local v, err = string.deserialize(extra)
        if err then
            raise(err)
        else
            extrainfo = v
        end
    end

    -- force to use the given requires extra info
    if extrainfo then
        requires_extra = requires_extra or {}
        for _, require_str in ipairs(requires) do
            requires_extra[require_str] = extrainfo
        end
    end
    return requires, requires_extra
end
