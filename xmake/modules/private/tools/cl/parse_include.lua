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
-- @file        parse_include.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")

-- contain: "Note: including file: "?
--
-- @note we cannot get better solution to distinguish between `includes` and `error infos`
--
function main(line)

    -- init notes
    --
    -- TODO zh-tw, zh-hk, jp, ...
    --
    _g.notes = _g.notes or
    {
        "Note: including file: "
    ,   "注意: 包含文件: "
    }

    -- contain notes?
    for idx, note in ipairs(_g.notes) do

        -- dump line bytes
        --[[
        print(line)
        line:gsub(".", function (ch) print(string.byte(ch)) end)
        --]]

        if line:startswith(note) then
            -- optimization: move this note to head
            if idx ~= 1 then
                table.insert(_g.notes, 1, note)
            end
            return line:sub(#note):trim()
        end
    end
end

