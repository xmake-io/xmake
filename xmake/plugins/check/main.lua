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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.text")
import("checker")

function _show_list()
    local tbl = {align = 'l', sep = "    "}
    local checkers = checker.checkers()
    local groups = {}
    for name, info in table.orderpairs(checkers) do
        local groupname = name:split(".", {plain = true})[1]
        if not groups[groupname] then
            table.insert(tbl, {})
            table.insert(tbl, {groupname:sub(1, 1):upper() .. groupname:sub(2) .. " checkers:"})
            groups[groupname] = true
        end
        table.insert(tbl, {{"  " .. name, style = "${color.dump.string_quote}"}, info.description})
    end
    cprint(text.table(tbl))
end

function _show_info(name)
    local checkers = checker.checkers()
    local info = checkers[name]
    if info then
        cprint("${color.dump.string}checker${clear}(%s):", name)
        cprint("  -> ${color.dump.string_quote}description${clear}: %s", info.description)
    else
        raise("checker(%s) not found!", name)
    end
end

function main()
    if option.get("list") then
        return _show_list()
    elseif option.get("info") then
        return _show_info(option.get("info"))
    end
end
