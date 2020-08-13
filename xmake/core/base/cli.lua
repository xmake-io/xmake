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
cli._segment = segment

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
    return cli._make_segment("arg", value, argv, argi, { value = value })
end

function cli._make_flag(key, short, argv, argi)
    return cli._make_segment("flag", short and ("-" .. key) or ("--" .. key), argv, argi, { key = key, value = true, short = short or false })
end

function cli._make_option(key, value, short, argv, argi)
    return cli._make_segment("option", short and ("-" .. key .. " " .. value) or ("--" .. key .. "=" .. value), argv, argi, { key = key, value = value, short = short or false })
end

-- parse a argv string, command & sub-command should be omitted before calling this function
-- @see https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
function cli.parse(args, flags)
    return cli.parsev(os.argv(args), flags)
end

-- parse a argv array, command & sub-command should be omitted before calling this function
-- @see https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
function cli.parsev(argv, flags)

    local parsed = {}
    local raw = false
    local index = 1
    local value = nil
    flags = hashset.from(flags or {})

    while index <= #argv do
        value = argv[index]
        if raw or not value:startswith("-") or #value < 2 then
            -- all args after "--" or first arg, args don"t start with "-", and short args (include a single char "-")
            raw = true
            table.insert(parsed, cli._make_arg(value, argv, index))
        elseif value == "--" then
            -- stop parsing after "--"
            raw = true
            table.insert(parsed, cli._make_segment("sep", "--", argv, index, {}))
        elseif value:startswith("--") then
            -- "--key:value", "--key=value", "--long-flag"
            local sep = value:find("[=:]", 3, false)
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

-- return module
return cli
