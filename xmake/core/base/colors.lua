--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        colors.lua
--

-- define module
local colors = colors or {}

-- load modules
local emoji = emoji or require("base/emoji")

-- the color keys
--
-- from https://github.com/hoelzro/ansicolors
--
colors.keys = 
{
    -- attributes
    reset       = 0
,   clear       = 0
,   default     = 0
,   bright      = 1
,   dim         = 2
,   underline   = 4
,   blink       = 5
,   reverse     = 7
,   hidden      = 8

    -- foreground 
,   black       = 30
,   red         = 31
,   green       = 32
,   yellow      = 33
,   blue        = 34
,   magenta     = 35
,   cyan        = 36
,   white       = 37

    -- background 
,   onblack     = 40
,   onred       = 41
,   ongreen     = 42
,   onyellow    = 43
,   onblue      = 44
,   onmagenta   = 45
,   oncyan      = 46
,   onwhite     = 47
}

-- the escape string
colors.escape = string.char(27) .. '[%sm'

-- is supported?
function colors.supported()

    -- this is supported if be not windows
    if xmake._HOST ~= "windows" then
        return true
    end

    -- this is supported if exists ANSICON envirnoment variable on windows
    return os.getenv("ANSICON") 
end

-- translate colors from the string
-- 
-- colors:
--
-- "${red}hello"
-- "${onred}hello${clear} xmake"
-- "${bright red underline}hello"
-- "${dim red}hello"
-- "${blink red}hello"
-- "${reverse red}hello xmake"
--
-- emoji:
--
-- "${beer}hello${beer}world"
--
function colors.translate(str)

    -- check string
    if not str then
        return nil
    end

    -- patch reset
    str = "${reset}" .. str .. "${reset}"

    -- translate it
    str = string.gsub(str, "(%${(.-)})", function(_, word) 

        -- not supported? ignore it
        if not colors.supported() then
            return ""
        end

        -- attempt to translate to emoji first
        local emoji_str = emoji.translate(word)
        if emoji_str then
            return emoji_str
        end

        -- make color buffer
        local buffer = {}
        for key in word:gmatch("%w+") do
            
            -- key to number
            local number = colors.keys[key]
            assert(number, "unknown color: " .. key)

            -- save this number
            table.insert(buffer, number)
        end

        -- format the color buffer
        return colors.escape:format(table.concat(buffer, ";"))
    end)

    -- ok
    return str
end

-- return module
return colors.translate
