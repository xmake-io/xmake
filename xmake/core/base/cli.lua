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
-- @file        cli.lua
--

-- define module
local cli = cli or {}
local segment = cli._segment or {}

-- load modules
local string    = require("base/string")
local hashset   = require("base/hashset")

segment.__index = segment

function segment:__tostring()
    return self.string
end

function segment:__todisplay()
    return string.format("${color.dump.string}%s${reset} ${color.dump.keyword}(%s)${reset}", self.string, self.type)
end

function segment:is(type)
    return self.type == type
end

function cli._make_segment(type, string, argv, argi, obj)
    obj.type = type
    obj.string = string
    obj.argv = argv
    obj.argi = argi
    return setmetatable(obj, segment)
end

function cli._make_arg(value, argv, argi)
    return cli._make_segment('arg', value, argv, argi, { value = value })
end

function cli._make_flag(key, short, argv, argi)
    return cli._make_segment('flag', short and ('-' .. key) or ('--' .. key), argv, argi, { key = key, value = true, short = short or false })
end

function cli._make_option(key, value, short, argv, argi)
    return cli._make_segment('option', short and ('-' .. key .. ' ' .. value) or ('--' .. key .. '=' .. value), argv, argi, { key = key, value = value, short = short or false })
end

function cli.parse(args, ...)
    return cli.parsev(os.argv(args), ...)
end

function cli.parsev(argv, flags)

    local parsed = {}
    local raw = false
    local index = 1
    local value = nil
    flags = hashset.from(flags or {})

    while index <= #argv do
        value = argv[index]
        if raw or not value:startswith('-') or #value < 2 then
            -- all args after '--' or first arg, args don't start with '-', and short args (include a single char '-')
            raw = true
            table.insert(parsed, cli._make_arg(value, argv, index))
        elseif value == '--' then
            -- stop parsing after '--'
            raw = true
            table.insert(parsed, cli._make_segment('sep', '--', argv, index, {}))
        elseif value:startswith('--') then
            -- '--key:value', '--key=value', '--long-flag'
            local sep = value:find('[=:]', 3, false)
            if sep then
                table.insert(parsed, cli._make_option(value:sub(3, sep - 1), value:sub(sep + 1), false, argv, index))
            else
                table.insert(parsed, cli._make_flag(value:sub(3), false, argv, index))
            end
        else
            local strp = 2
            while strp <= #value do
                local ch = value:sub(strp, strp)
                if flags:has(ch) then
                    -- is a flag
                    table.insert(parsed, cli._make_flag(ch, true, argv, index))
                else
                    -- is an option
                    if strp == #value then
                        -- is last char, use next arg as value
                        table.insert(parsed, cli._make_option(ch, argv[index + 1] or "", true, argv, index))
                        index = index + 1
                    else
                        -- is not last char, use remaining as value
                        table.insert(parsed, cli._make_option(ch, value:sub(strp + 1), true, argv, index))
                        strp = #value
                    end
                end
                strp = strp + 1
            end
        end
        index = index + 1
    end
    return parsed
end

-- @see https://unicode.org/reports/tr14/
function cli._lastwbr(str, width, wordbreak)

    -- check
    assert(#str >= width)

    if wordbreak == "breakall" then
        -- To prevent overflow, word may be broken at any character
        return width
    else

        if str:sub(width + 1, width + 1):find("[%s]") then
            -- exact break
            return width
        end

        local range = str:sub(1, width)
        local poss = range:reverse():find("[%s-]")
        if poss then
            return #range - poss + 1
        end

        -- not found in range, try afterwards
        poss = str:find("[%s-]", width + 1)
        if poss then
            return poss
        end

        -- not found in all str
        return #str
    end
end

-- break lines
function cli.wordwrap(str, width, opt)

    opt = opt or {}

    -- split to lines
    if type(str) == 'table' then
        str = table.concat(str, '\n')
    end
    local lines = tostring(str):split('\n', {plain = true, strict = true})

    local result = {}
    -- handle lines
    for _, v in ipairs(lines) do

        -- remove tailing spaces, include '\r', which will be produced by `('l1\r\nl2'):split(...)`
        v = v:rtrim()
        while #v > width do

            -- find word break chance
            local wbr = cli._lastwbr(v, width, opt.wordbreak)

            -- break line
            local line = v:sub(1, wbr):rtrim()
            table.insert(result, line)
            v = v:sub(wbr + 1):ltrim()

            -- prevent empty line
            if #v == 0 then v = nil end
        end

        -- put remaining parts
        table.insert(result, v)
    end

    -- ok
    return result
end

cli._segment = segment
-- return module
return cli
