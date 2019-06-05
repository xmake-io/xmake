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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        complete.lua
--

-- imports
import("core.base.option")
import("core.base.task")

local tasks = task.tasks()
local shortnames = {}
for k, v in pairs(tasks) do
    if v.shortname then
        shortnames[menu.shortname] = k
    end
end

function _print_candidate(...)
    local candidate = format(...)
    if candidate and #candidate ~= 0 then
        print(candidate)
    end
end

function _complete_task(name)
    local has_candidate = false
    for k, _ in pairs(tasks) do
        if k:startswith(name) then
            _print_candidate(k)
            has_candidate = true
        end
    end
    for k, _ in pairs(tasks) do
        -- not startswith
        if k:find(name, 2, true) then
            _print_candidate(k)
            has_candidate = true
        end
    end
    return has_candidate
end

function _complete_option(options, name)
    local state = 0
    if name == "-" or name == "--" then
        name = ""
    elseif name:startswith("--") then
        state = 2
        name = name:sub(3)
    elseif name:startswith("-") then
        state = 1
        name = name:sub(2)
    end

    -- search full names only
    if name == "" then state = 2 end

    local opcandi = {}
    for _, v in ipairs(options) do
        if v[3] == "kv" or v[3] == "k" then table.insert(opcandi, v) end
    end

    for _, v in ipairs(opcandi) do
        if (state == 2 or state == 0) and v[2]:startswith(name) then
            _print_candidate((v[3] == "k") and "--%s" or "--%s=", v[2])
        elseif (state == 1 or state == 0) and v[1] and v[1]:startswith(name) then
            _print_candidate((v[3] == "k") and "-%s" or "-%s ", v[1])
        end
    end
    for _, v in ipairs(opcandi) do
        -- not startswith
        if (state == 2 or state == 0) and v[2]:find(name, 2, true) then
            _print_candidate((v[3] == "k") and "--%s" or "--%s=", v[2])
        elseif (state == 1 or state == 0) and v[1] and v[1]:find(name, 2, true) then
            _print_candidate((v[3] == "k") and "-%s" or "-%s ", v[1])
        end
    end
end

function main(position, ...)
    word = table.concat({...}, " ") or ""
    position = tonumber(position) or 0
    if position > #word then
        word = word .. " "
    end
    if word:lower():startswith("xmake ") then
        word = word:sub(#"xmake " + 1)
    end
    if word:lower() == "xmake" then
        return _complete_task("")
    end

    local segs = word:split("%s")
    local task = table.remove(segs, 1) or ""
    if #segs == 0 and not word:endswith(" ") then
        if _complete_task(task) then return end
    end

    if shortnames[task] then task = shortnames[task] end
    if not tasks[task] then
        table.insert(segs, 1, task)
        task = "run"
    end
    _complete_option(option.taskmenu(task).options, word:endswith(" ") and "" or segs[#segs])
    return
end