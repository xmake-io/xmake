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
-- @author      OpportunityLiu
-- @file        complete.lua
--

-- imports
import("core.base.option")
import("core.base.task")

local use_spaces = true
local raw_words = {}
local word = ""
local position = 0
local has_space = false
local reenter = false

function _print_candidate(is_complate, ...)
    local candidate = format(...)
    if candidate and #candidate ~= 0 then
        printf(candidate)
        if use_spaces and is_complate then
            print(" ")
        else
            print("")
        end
    end
end

function _complete_task(tasks, name)
    local has_candidate = false
    for k, _ in pairs(tasks) do
        if k:startswith(name) then
            _print_candidate(true, "%s", k)
            has_candidate = true
        end
    end

    if name == "" then
        return has_candidate
    end

    for k, _ in pairs(tasks) do
        -- not startswith
        if k:find(name, 2, true) then
            _print_candidate(true, "%s", k)
            has_candidate = true
        end
    end
    return has_candidate
end

function _complete_option(options, segs, name)
    local current_options = try
    {
        function()
            return option.raw_parse(segs, options, { populate_defaults = false, allow_unknown = true })
        end
    }
    -- current options is invalid
    if not current_options then return end

    -- current context is wrong
    if not reenter and (current_options.file or current_options.project) then
        local args = {"lua", "--root", "private.utils.complete", tostring(position), use_spaces and "reenter" or "nospace-reenter", table.unpack(raw_words) }
        if current_options.file then
            table.insert(args, 3, "--file=" .. current_options.file)
        end
        if current_options.project then
            table.insert(args, 3, "--project=" .. current_options.project)
        end
        os.execv("xmake", args)
        return
    end

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
        if current_options[v[2]] == nil then
            if v[3] == "kv" or v[3] == "k" then table.insert(opcandi, v) end
        end
    end

    for _, v in ipairs(opcandi) do
        if (state == 2 or state == 0) and v[2]:startswith(name) then
            _print_candidate((v[3] == "k"), (v[3] == "k") and "--%s" or "--%s=", v[2])
        elseif (state == 1 or state == 0) and v[1] and v[1]:startswith(name) then
            _print_candidate(true, "-%s", v[1])
        end
    end

    if name == "" then
        return
    end

    for _, v in ipairs(opcandi) do
        -- not startswith
        if (state == 2 or state == 0) and v[2]:find(name, 2, true) then
            _print_candidate((v[3] == "k"), (v[3] == "k") and "--%s" or "--%s=", v[2])
        elseif (state == 1 or state == 0) and v[1] and v[1]:find(name, 2, true) then
            _print_candidate(true, "-%s", v[1])
        end
    end
end

function _complete()

    local tasks = {}
    local shortnames = {}
    for _, v in ipairs(task.names()) do
        local menu = option.taskmenu(v)
        tasks[v] = menu
        if menu.shortname then
            shortnames[menu.shortname] = v
        end
    end

    if word:lower() == "xmake" then
        _complete_task(tasks, "")
        return
    end

    local segs = word:split("%s")
    local task_name = table.remove(segs, 1) or ""

    if #segs == 0 and not has_space then
        if _complete_task(tasks, task_name) then return end
    end

    if shortnames[task_name] then task_name = shortnames[task_name] end
    if not tasks[task_name] then
        table.insert(segs, 1, task_name)
        task_name = "run"
    end

    local incomplete_option = has_space and "" or segs[#segs]
    if not has_space then segs[#segs] = nil end

    _complete_option(tasks[task_name].options, segs, incomplete_option)
end

function main(pos, config, ...)

    raw_words = {...}
    local words = {...}

    local is_config = false
    if config:find("nospace", 1, true) then
        use_spaces = false
        is_config = true
    end
    if config:find("reenter", 1, true) then
        reenter = true
        is_config = true
    end

    if not is_config then
        table.insert(words, 1, config)
    end

    word = table.concat(words, " ") or ""
    position = tonumber(pos) or 0
    has_space = word:endswith(" ") or position > #word
    word = word:trim()

    -- normailize word to "xmake ..."
    if is_host("windows") then
        if word:lower():startswith("xmake.exe") then
            word = "xmake" .. word:sub(#"xmake.exe" + 1)
        end
    end

    if word:lower():startswith("xmake ") then
        word = word:sub(#"xmake " + 1)
    end

    _complete()
end