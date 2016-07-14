--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
