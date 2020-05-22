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
local raw_config
local position = 0
local use_spaces = true
local no_key = false
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

function _find_candidates(candidates, find)

    if type(candidates) ~= 'table' then
        return {}
    end

    local has_candidate = false
    local results = table.new(#candidates, 0)

    -- find candidate starts with find str
    for _, v in ipairs(candidates) do
        if tostring(v):startswith(find) then
            table.insert(results, v)
            has_candidate = true
        end
    end

    -- stop searching if found any
    if has_candidate then
        return results
    end

    -- find candidate contains find str
    for _, v in ipairs(candidates) do
        if tostring(v):find(find, 1, true) then
            table.insert(results, v)
        end
    end

    return results
end

function _complete_task(tasks, name)
    local has_candidate = false
    for _, v in ipairs(_find_candidates((table.keys(tasks)), name)) do
        _print_candidate(true, "%s", v)
        has_candidate = true
    end
    return has_candidate
end

-- complete values of kv
function _complete_option_kv_v(options, current, completing, name, value)

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
        values = values(value, current)
    end
    if values == nil and type(opt[4]) == "boolean" then
        values = { "yes", "no" }
        -- ignore existing input
        value = ""
    end

    -- match values starts with value first
    for _, v in ipairs(_find_candidates(values, value)) do
        if no_key then
            _print_candidate(true, "%s", v)
        else
            _print_candidate(true, "--%s=%s", name, v)
        end
    end

    -- whether any candidates has been found, finish complete since we don't have more info
    return true
end

-- complete keys of kv
function _complete_option_kv_k(options, current, completing, name)

    local opcandi = table.new(0, 10)
    for _, opt in ipairs(options) do
        if opt[2] and current[opt[2]] == nil and (opt[3] == "kv" or opt[3] == "k") then
            opcandi[opt[2]] = opt
        end
    end

    for _, k in ipairs(_find_candidates((table.keys(opcandi)), name)) do
        local opt = opcandi[k]
        _print_candidate((opt[3] == "k"), (opt[3] == "k") and "--%s" or "--%s=", opt[2])
    end

    return true
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
        return _complete_option_kv_v(options, current, completing, name, value)
    else
        -- complete keys
        return _complete_option_kv_k(options, current, completing, name)
    end
end

-- complete options v and vs
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
            values = values(completing, current)
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
        local args = {"lua", "private.utils.complete", tostring(position), raw_config .. "-reenter", table.unpack(raw_words) }
        if current_options.file then
            table.insert(args, 2, "--file=" .. current_options.file)
        end
        if current_options.project then
            table.insert(args, 2, "--project=" .. current_options.project)
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

    raw_config = (config or ""):trim()
    if raw_config:find("nospace", 1, true) then
        use_spaces = false
    end
    if raw_config:find("reenter", 1, true) then
        reenter = true
    end
    if raw_config:find("nokey", 1, true) then
        no_key = true
    end
    if raw_config:find("debug", 1, true) then
        debug = true
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

