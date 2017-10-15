--!A cross-platform build utility based on Lua
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

-- the 256 color keys
--
-- from https://github.com/hoelzro/ansicolors
--
colors._keys256 = 
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

-- the 24bits color keys
--
-- from https://github.com/hoelzro/ansicolors
--
colors._keys24 = 
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
,   black       = "38;2;0;0;0"
,   red         = "38;2;255;0;0"
,   green       = "38;2;0;255;0"
,   yellow      = "38;2;255;255;0"
,   blue        = "38;2;0;0;255"
,   magenta     = "38;2;255;0;255"
,   cyan        = "38;2;0;255;255"
,   white       = "38;2;255;255;255"

    -- background 
,   onblack     = "48;2;0;0;0"
,   onred       = "48;2;255;0;0"
,   ongreen     = "48;2;0;255;0"
,   onyellow    = "48;2;255;255;0"
,   onblue      = "48;2;0;0;255"
,   onmagenta   = "48;2;255;0;255"
,   oncyan      = "48;2;0;255;255"
,   onwhite     = "48;2;255;255;255"
}

-- the escape string
colors._escape = string.char(27) .. '[%sm'

-- support 256 colors?
--
-- COLORTERM: color256, truecolor, nocolor
--
function colors.has256()

    -- get $COLORTERM
    colors._COLORTERM = colors._COLORTERM or os.getenv("COLORTERM") or ""

    -- no color?
    if colors._COLORTERM == "nocolor" then
        return false
    end

    -- has 256 color?
    if colors._COLORTERM == "color256" or os.host() ~= "windows" then
        return true
    end

    -- this is supported if exists ANSICON envirnoment variable on windows
    colors._ANSICON = colors._ANSICON or os.getenv("ANSICON")
    return colors._ANSICON
end

-- support 24bits true color
--
-- There's no reliable way, and ncurses/terminfo's maintainer expressed he has no intent on introducing support. 
-- S-Lang author added a check for $COLORTERM containing either "truecolor" or "24bit" (case sensitive).
-- In turn, VTE, Konsole and iTerm2 set this variable to "truecolor" (it's been there in VTE for a while, 
-- it's relatively new and maybe still git-only in Konsole and iTerm2).
--
-- This is obviously not a reliable method, and is not forwarded via sudo, ssh etc. However, whenever it errs, 
-- it errs on the safe side: does not advertise support whereas it's actually supported. 
-- App developers can freely choose to check for this same variable, or introduce their own method
-- (e.g. an option in their config file), whichever matches better the overall design of the given app. 
-- Checking $COLORTERM is recommended though, since that would lead to a more unique desktop experience 
-- where the user has to set one variable only and it takes effect across all the apps, rather than something 
-- separately for each app.
--
function colors.truecolor()

    -- get $COLORTERM
    colors._COLORTERM = colors._COLORTERM or os.getenv("COLORTERM") or ""

    -- support true color?
    return colors._COLORTERM:find("truecolor", 1, true) or colors._COLORTERM:find("24bit", 1, true)
end

-- make rainbow color code by the index of characters
--
-- @param index     the index of characters
-- @param seed      the seed, 0-255, default: random
-- @param freq      the frequency, default: 0.1
-- @param spread    the spread, default: 3.0 
--
--
function colors.rainbow(index, seed, freq, spread)

    -- init values
    seed   = seed
    freq   = freq or 0.1
    spread = spread or 3.0
    index  = seed + index / spread

    -- make colors
    local red   = math.sin(freq * index + 0) * 127 + 128
    local green = math.sin(freq * index + 2 * math.pi / 3) * 127 + 128
    local blue  = math.sin(freq * index + 4 * math.pi / 3) * 127 + 128

    -- make code
    return string.format("%d;%d;%d", red, green, blue)
end

-- translate colors from the string
--
-- @param str       the string with colors
-- @param force     force to translate all colors? 
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
-- true colors:
--
-- "${255;0;0}hello"
-- "${on;255;0;0}hello${clear} xmake"
-- "${bright 255;0;0 underline}hello"
-- "${bright on;255;0;0 0;255;0}hello${clear} xmake"
--
-- emoji:
--
-- "${beer}hello${beer}world"
--
function colors.translate(str, force)

    -- check string
    if not str then
        return nil
    end

    -- patch reset
    str = "${reset}" .. str .. "${reset}"

    -- translate it
    str = string.gsub(str, "(%${(.-)})", function(_, word) 

        -- ignore all colors if no tty (redirect ..)
        if not force and not io.isatty() then
            return ""
        end

        -- not supported? ignore it
        if not colors.has256() and not colors.truecolor() then
            return ""
        end

        -- attempt to translate to emoji first
        local emoji_str = emoji.translate(word)
        if emoji_str then
            return emoji_str
        end

        -- get keys
        local keys = colors._keys256
        if colors.truecolor() then
            keys = colors._keys24
        end

        -- make color buffer
        local buffer = {}
        for _, key in ipairs(word:split("%s+")) do

            -- get the color code
            local code = keys[key]
            if not code and key:find(";", 1, true) and colors.truecolor() then
                if key:startswith("on;") then
                    code = key:gsub("on;", "48;2;")
                else
                    code = "38;2;" .. key
                end
            end
            assert(code, "unknown color: " .. key)

            -- save this code
            table.insert(buffer, code)
        end

        -- format the color buffer
        return colors._escape:format(table.concat(buffer, ";"))
    end)

    -- ok
    return str
end

-- ignore all colors
function colors.ignore(str)

    -- check string
    if not str then
        return nil
    end

    -- ignore it
    return (string.gsub(str, "(%${(.-)})", ""))
end

-- return module
return colors
