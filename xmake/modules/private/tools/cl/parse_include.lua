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

-- probe include note prefix from cl
function _probe_include_note_from_cl()
    -- TODO
end

-- get include notes prefix, e.g. "Note: including file: "
--
-- @note we cannot get better solution to distinguish between `includes` and `error infos`
--
function _get_include_notes()
    local notes = _g.notes
    if not notes then
        notes = {}
        local note = _probe_include_note_from_cl()
        if note then
            table.insert(notes, note)
        end
        table.join2(notes, {
            "Note: including file: ", -- en
            "注意: 包含文件: ", -- zh
            "Remarque : inclusion du fichier : ", -- fr
            "メモ: インクルード ファイル: " -- jp
        })
        _g.notes = notes
    end
    return notes
end

-- main entry
function main(line)

    -- contain notes?
    local notes = _get_include_notes()
    for idx, note in ipairs(notes) do
        if line:startswith(note) then
            -- optimization: move this note to head
            if idx ~= 1 then
                table.insert(notes, 1, note)
            end
            return line:sub(#note):trim()
        end
    end
end

