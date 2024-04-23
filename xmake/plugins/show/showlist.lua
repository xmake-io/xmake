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
-- @file        showlist.lua
--

-- imports
import("core.base.option")
import("core.base.text")
import("core.base.json")

function _show_text(values)
    local tbl = {align = 'l', sep = "    "}
    local row = {}
    for _, value in ipairs(values) do
        table.insert(row, value)
        if #row > 2 then
            table.insert(tbl, row)
            row = {}
        end
    end
    if #row > 0 then
        table.insert(tbl, row)
    end
    print(text.table(tbl))
end

function _show_json(values)
    print(json.encode(values))
end

function main(values)
    if option.get("json") then
        _show_json(values)
    else
        if table.is_dictionary(values) then
            for k, v in pairs(values) do
                cprint("${bright}%s:", k)
                _show_text(v)
            end
        else
            _show_text(values)
        end
    end
end
