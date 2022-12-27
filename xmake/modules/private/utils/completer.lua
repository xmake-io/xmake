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
-- @author      OpportunityLiu, glcraft
-- @file        complete.lua
--

-- imports
import("core.base.option")
import("core.base.cli")

local completer = {}


function completer.new(pos, config, words)
    local instance = table.inherit(completer)
    instance._POSITION = 0
    instance._CONFIG = {}
    instance._WORDS = {}
    instance._DEFAULT_COMMAND = ""
    instance:set_config(config)
    instance:set_position(pos)
    instance:set_words(words)
    return instance
end

function completer:_print_candidate(candidate)
    if candidate.value and #candidate.value ~= 0 then
        printf(candidate.value)
        if not self:config("nospace") and candidate.is_complete then
            print(" ")
        else
            print("")
        end
    end
end

function completer:_print_candidates(candidates)
    if self:config("json") then 
        import("core.base.json")
        print(json.encode(candidates))
    else
        for _, v in ipairs(candidates) do
            self:_print_candidate(v)
        end
    end 
end

function completer:_find_candidates(candidates, find)

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

function completer:_complete_item(items, name)
    local found_candidates = {}
    for _, v in ipairs(self:_find_candidates(table.keys(items), name)) do
        table.insert(found_candidates, { value = v, is_complete = true, description = items[v].description })
    end
    self:_print_candidates(found_candidates)
    return #found_candidates > 0 
end

-- complete values of kv
function completer:_complete_option_kv_v(options, current, completing, name, value)

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
    local found_candidates = {}
    local nokey = self:config("nokey")
    for _, v in ipairs(_find_candidates(values, value)) do
        if nokey then
            table.insert(found_candidates, { value = v, is_complete = true })
        else
            table.insert(found_candidates, { value = format("--%s=%s", name, v), is_complete = true })
        end
    end
    completer:_print_candidates(found_candidates)

    -- whether any candidates has been found, finish complete since we don't have more info
    return true
end

-- complete keys of kv
function completer:_complete_option_kv_k(options, current, completing, name)

    local opcandi = table.new(0, 10)
    for _, opt in ipairs(options) do
        if opt[2] and current[opt[2]] == nil and (opt[3] == "kv" or opt[3] == "k") then
            opcandi[opt[2]] = opt
        end
    end
    local found_candidates = {}
    for _, k in ipairs(self:_find_candidates((table.keys(opcandi)), name)) do
        local opt = opcandi[k]
        local name = format((opt[3] == "k") and "--%s" or "--%s=", opt[2])
        table.insert(found_candidates, { value = name, description = opt[5], is_complete = (opt[3] == "k") })
    end
    self:_print_candidates(found_candidates)

    return true
end

function completer:_complete_option_kv(options, current, completing)

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
        return self:_complete_option_kv_v(options, current, completing, name, value)
    else
        -- complete keys
        return self:_complete_option_kv_k(options, current, completing, name)
    end
end

-- complete options v and vs
function completer:_complete_option_v(options, current, completing)
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
    -- transform values array to candidates array
    local function _transform_values(values)
        local candidates = {}
        if #values > 0 and type(values[1]) == "string" then
            for _, v in ipairs(values) do
                table.insert(candidates, { value = v, is_complete = true })
            end
        else
            for _, v in ipairs(values) do
                v.is_complete=true
                table.insert(candidates, v)
            end
        end
        return candidates
    end
    -- filter candidates with completing
    local function _filter_candidates(candidates)
        local found_candidates = {}
        for _, v in ipairs(candidates) do
            if v.value:find(completing,1,true) then
                v.is_complete=true
                table.insert(found_candidates, v)
            end
        end
        return found_candidates
    end
    -- get completion candidates from values option
    local function _values_into_candidates(values)
        if values == nil then
            return {}
        elseif type(values) == "function" then
            -- no need to filter result of values() as we consider values() already filter candidates
            return _transform_values(values(completing, current))
        else
            return _filter_candidates(_transform_values(values))
        end
    end

    local found_candidates = {}
    if opt then
        -- get candidates from values option
        found_candidates = _values_into_candidates(opt.values)
    end

    if optvs and #found_candidates == 0 then
        -- get candidates from values option
        found_candidates = _values_into_candidates(optvs.values)
    end
    self:_print_candidates(found_candidates)
    return #found_candidates > 0
end

function completer:_complete_option(options, segs, completing)
    local current_options = try
    {
        function()
            return option.raw_parse(segs, options, { populate_defaults = false, allow_unknown = true })
        end
    }
    -- current options is invalid
    if not current_options then return false end

    -- current context is wrong
    if not self:config("reenter") and (current_options.file or current_options.project) then
        local args = {"lua", "private.utils.complete", tostring(position), table.concat(self._CONFIG, "-") .. "-reenter", table.unpack(raw_words) }
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
        return self:_complete_option_kv(options, current_options, completing)
    else
        return self:_complete_option_v(options, current_options, completing)
    end
end

function completer:complete(items, argv, completing)

    local shortnames = table.new(0, 10)
    for v, menu in pairs(items) do
        -- local menu = items[v]
        if menu.shortname then
            shortnames[menu.shortname] = v
        end
    end

    if #argv == 0 then
        if self:_complete_item(items, completing) then return end
    end

    local item_name = self:default_command()
    if argv[1] and not argv[1]:startswith("-") then
        item_name = table.remove(argv, 1)
    end

    if shortnames[item_name] then item_name = shortnames[item_name] end

    local options
    if items[item_name] then
        options = items[item_name].options
    end

    if options then
        self:_complete_option(options, argv, completing)
    end
end

function completer:set_words(raw_words)
    self._WORDS = raw_words
end

function completer:words()
    return self._WORDS
end

function completer:set_position(pos)
    self._POSITION = pos
end

function completer:position()
    return self._POSITION
end

function completer:set_default_command(command)
    self._DEFAULT_COMMAND = command
end

function completer:default_command()
    return self._DEFAULT_COMMAND
end

function completer:set_config(config)
    self._CONFIG = (config or ""):trim():split("-")
end

function completer:config(key)
    return table.find_first(self._CONFIG, key)
end

function new(...)
    return completer.new(...)
end