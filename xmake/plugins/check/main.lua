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
import("core.project.config")
import("private.check.checker")

-- show checkers list
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

-- show checker information
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

-- do check
function _check(group_or_name, arguments)

    -- load config
    config.load()

    -- get checkers
    local checked_checkers = {}
    local checkers = checker.checkers()
    if checkers[group_or_name] then
        table.insert(checked_checkers, group_or_name)
    else
        for name, _ in table.orderpairs(checkers) do
            if name:startswith(group_or_name .. ".") then
                table.insert(checked_checkers, name)
            end
        end
    end
    assert(#checked_checkers > 0, "checker(%s) not found!", group_or_name)

    -- do checkers
    local showstats
    for _, name in ipairs(checked_checkers) do
        local info = checkers[name]
        if showstats == nil and info and info.showstats ~= nil then
            showstats = info.showstats
        end
        import("private.check.checkers." .. name, {anonymous = true})(arguments)
    end
    if showstats ~= false then
        checker.show_stats()
    end
end

function main()
    if option.get("list") then
        _show_list()
    elseif option.get("info") then
        _show_info(option.get("info"))
    elseif option.get("checkers") then
        _check(option.get("checkers"), option.get("arguments"))
    end
end
