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
import("core.base.cli")

local raw_words = {}
local position = 0
local use_spaces = true
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

function _complete_option_kv(options, current, completing)

    local name, value
    if completing == "-" or completing == "--" then
        name = ""
    elseif completing:startswith("--") then
        local parg = cli.parsev({completing})[1]
        if parg.type == "option" then
            name, value = parg.key, parg.value
        elseif parg.type == "flag" then
            name = parg.key
        end
    elseif completing:startswith("-") then
        -- search full names only
        return true
    end

    if value then
        -- complete values

        -- find completion option
        local opt
        for _, v in ipairs(options) do
            if v[3] == "kv" and (v[1] == name or v[2] == name) then
                opt = v
                break
            end
        end
        if not opt then
            return false
        end

        -- show candidates of values
        local values = opt.values
        if type(values) == "function" then
            values = values(value)
        end
        if values == nil and type(opt[4]) == "boolean" then
            values = { "y", "n" }
            -- ignore existing input
            value = ""
        end
        for _, v in ipairs(values) do
            if tostring(v):startswith(value) then
                _print_candidate(true, "--%s=%s", name, v)
            end
        end
        return true
    end

    local opcandi = table.new(10, 0)
    for _, v in ipairs(options) do
        if current[v[2]] == nil then
            if v[3] == "kv" or v[3] == "k" then table.insert(opcandi, v) end
        end
    end

    for _, v in ipairs(opcandi) do
        -- startswith
        if v[2]:startswith(name) then
            _print_candidate((v[3] == "k"), (v[3] == "k") and "--%s" or "--%s=", v[2])
        end
    end

    if name == "" then
        return true
    end

    for _, v in ipairs(opcandi) do
        -- not startswith
        if v[2]:find(name, 2, true) then
            _print_candidate((v[3] == "k"), (v[3] == "k") and "--%s" or "--%s=", v[2])
        end
    end

    return true
end

function _complete_option_v(options, current, completing)
    -- find completion option
    local opt
    local optvs
    for _, v in ipairs(options) do
        if v[3] == "v" and current[v[2] or v[1]] == nil then
            opt = v
        end
        if v[3] == "vs" and not optvs then
            optvs = v
        end
    end

    if opt then
        -- show candidates of values
        local values = opt.values
        if type(values) == "function" then
            values = values(completing)
        end
        for _, v in ipairs(values) do
            if tostring(v):startswith(completing) then
                _print_candidate(true, "%s", v)
            end
        end
        return true
    end

    if optvs then

        -- show candidates of values
        local values = optvs.values
        if type(values) == "function" then
            values = values(completing)
        end
        for _, v in ipairs(values) do
            if tostring(v):startswith(completing) then
                _print_candidate(true, "%s", v)
            end
        end
        return true
    end

    return false
end

function _complete_option(options, segs, completing)
    local current_options = try
    {
        function()
            return option.raw_parse(segs, options, { populate_defaults = false, allow_unknown = true })
        end
    }
    -- current options is invalid
    if not current_options then return false end

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
        return true
    end

    if completing:startswith("-") then
        return _complete_option_kv(options, current_options, completing)
    else
        return _complete_option_v(options, current_options, completing)
    end
end

function _complete(argv, completing)

    local tasks = table.new(10, 0)
    local shortnames = table.new(0, 10)
    for _, v in ipairs(task.names()) do
        local menu = option.taskmenu(v)
        tasks[v] = menu
        if menu.shortname then
            shortnames[menu.shortname] = v
        end
    end

    if #argv == 0 then
        if _complete_task(tasks, completing) then return end
    end

    local task_name = "build"
    if argv[1] and not argv[1]:startswith("-") then
        task_name = table.remove(argv, 1)
    end

    if shortnames[task_name] then task_name = shortnames[task_name] end

    local options
    if tasks[task_name] then
        options = tasks[task_name].options
    else
        options = tasks["build"].options
    end

    _complete_option(options, argv, completing)
end

function main(pos, config, ...)

    raw_words = {...}

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
        table.insert(raw_words, 1, config)
    end

    local word = table.concat(raw_words, " ") or ""
    position = tonumber(pos) or 0
    local has_space = word:endswith(" ") or position > #word
    word = word:trim()

    local argv = os.argv(word)

    if argv[1] then

        -- normailize word to remove "xmake"
        if is_host("windows") and argv[1]:lower() == "xmake.exe" then
            argv[1] = "xmake"
        end
        if argv[1] == "xmake" then
            table.remove(argv, 1)
        end
    end

    if has_space then
        _complete(argv, "")
    else
        local completing = table.remove(argv)
        _complete(argv, completing or "")
    end
end

