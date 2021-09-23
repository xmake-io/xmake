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
-- @author      ruki
-- @file        colors.lua
--

-- define module
local colors = colors or {}

-- load modules
local tty -- lazy loading it
local emoji = require("base/emoji")

-- the color8 keys
--
-- from https://github.com/hoelzro/ansicolors
--
colors._keys8 =
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

-- the color256 keys
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
,   black       = "38;5;0"
,   red         = "38;5;1"
,   green       = "38;5;2"
,   yellow      = "38;5;3"
,   blue        = "38;5;4"
,   magenta     = "38;5;5"
,   cyan        = "38;5;6"
,   white       = "38;5;7"

    -- background
,   onblack     = "48;5;0"
,   onred       = "48;5;1"
,   ongreen     = "48;5;2"
,   onyellow    = "48;5;3"
,   onblue      = "48;5;4"
,   onmagenta   = "48;5;5"
,   oncyan      = "48;5;6"
,   onwhite     = "48;5;7"
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
colors._ESC = '\x1b[%sm'

-- make rainbow truecolor code by the index of characters
--
-- @param index     the index of characters
-- @param seed      the seed, 0-255, default: random
-- @param freq      the frequency, default: 0.1
-- @param spread    the spread, default: 3.0
--
--
function colors.rainbow24(index, seed, freq, spread)

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
    return string.format("%d;%d;%d", math.floor(red), math.floor(green), math.floor(blue))
end

-- make rainbow color256 code by the index of characters (16-256)
--
-- @param index     the index of characters
-- @param seed      the seed, 0-255, default: random
-- @param freq      the frequency, default: 0.1
-- @param spread    the spread, default: 3.0
--
--
function colors.rainbow256(index, seed, freq, spread)

    -- init values
    seed   = seed
    freq   = freq or 0.1
    spread = spread or 3.0
    index  = seed + index / spread

    -- make color code
    local code = math.floor((freq * index) % 240 + 18)

    -- make code
    return string.format("#%d", code)
end

-- translate colors from the string
--
-- @param str          the string with colors
-- @param opt          options
--                       patch_reset: wrap str with `"${reset}"`?
--                       ignore_unknown: ignore unknown codes like `"${unknown_code}"`?
--                       plain: false
--
-- 8 colors:
--
-- "${red}hello"
-- "${onred}hello${clear} xmake"
-- "${bright red underline}hello"
-- "${dim red}hello"
-- "${blink red}hello"
-- "${reverse red}hello xmake"
--
-- 256 colors:
--
-- "${#255}hello"
-- "${on#255}hello${clear} xmake"
-- "${bright #255; underline}hello"
-- "${bright on#255 #10}hello${clear} xmake"
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
-- theme:
-- "${color.error}"
-- "${bright color.warning}"
--
-- text:
-- "${hello xmake}"
-- "${hello xmake $beer}"
--
function colors.translate(str, opt)

    -- check string
    if not str then
        return nil
    end

    opt = opt or {}

    -- get theme
    local theme = colors.theme()

    -- patch reset
    if opt.patch_reset ~= false then
        str = "${reset}" .. str .. "${reset}"
    end

    -- translate color blocks, e.g. ${red}, ${color.xxx}, ${emoji}
    tty = tty or require("base/tty")
    local has_color8   = tty.has_color8()
    local has_color256 = tty.has_color256()
    local has_color24  = tty.has_color24()
    local has_emoji    = tty.has_emoji()
    str = str:gsub("(%${(.-)})", function(_, word)

        -- not supported? ignore it
        local nocolors = false
        if not has_color8 and not has_color256 and not has_color24 then
            nocolors = true
        end

        -- is plain theme? no colors and no emoji
        local noemoji = not has_emoji
        if opt.plain or (theme and theme:name() == "plain") then
            nocolors = true
            noemoji = true
        end

        -- get keys
        local keys = has_color256 and colors._keys256 or colors._keys8
        if has_color24 then
            keys = colors._keys24
        end

        -- split words
        local blocks_raw = word:split(' ', {plain = true})

        -- translate theme color first, e.g ${color.error}
        local blocks = {}
        for _, block in ipairs(blocks_raw) do
            if theme then
                local theme_block = theme:get(block)
                if theme_block then
                    for _, theme_block_sub in ipairs(theme_block:split(' ', {plain = true})) do
                        table.insert(blocks, theme_block_sub)
                    end
                else
                    table.insert(blocks, block)
                end
            elseif block:startswith("color.") or block:startswith("text.") then
                local default_theme = {["color.error"] = "red", ["color.warning"] = "yellow", ["text.error"] = "error", ["text.warning"] = "warning"}
                local theme_block = default_theme[block]
                if theme_block then
                    table.insert(blocks, theme_block)
                else
                    table.insert(blocks, block)
                end
            else
                table.insert(blocks, block)
            end
        end

        -- make color buffer
        local text_buffer = {}
        local color_buffer = {}
        for _, block in ipairs(blocks) do

            -- get the color code
            local code = keys[block]
            if not code then
                if has_color24 and block:find(";", 1, true) then
                    if block:startswith("on;") then
                        code = block:gsub("on;", "48;2;")
                    else
                        code = "38;2;" .. block
                    end
                elseif has_color256 and block:find("#", 1, true) then
                    if block:startswith("on#") then
                        code = block:gsub("on#", "48;5;")
                    else
                        code = block:gsub("#", "38;5;")
                    end
                elseif block:startswith("$") then
                    -- plain text, do not translate emoji
                    table.insert(text_buffer, block:sub(2))
                elseif not noemoji then
                    -- get emoji code
                    local emoji_code = emoji.translate(block)
                    if emoji_code then
                        table.insert(text_buffer, emoji_code)
                    elseif not opt.ignore_unknown then
                        -- unknown code, regard as plain text
                        table.insert(text_buffer, block)
                    end
                elseif not opt.ignore_unknown then
                    table.insert(text_buffer, block)
                end
            end

            -- save this code
            table.insert(color_buffer, code)
        end

        -- make result
        local result = ""
        if #color_buffer > 0 and not nocolors then
            result = result .. colors._ESC:format(table.concat(color_buffer, ";"))
        end
        if #text_buffer > 0 then
            result = result .. table.concat(text_buffer, " ")
        end
        return result
    end)
    return str
end

-- ignore all colors
function colors.ignore(str)
    if str then
        -- strip "${red}" and "${theme color}"
        str = colors.translate(str, {plain = true})
        -- strip color code, e.g. for clang/gcc color diagnostics output
        return (str:gsub("\x1b%[.-m", ""))
    end
end

-- get theme
function colors.theme()
    return colors._THEME
end

-- set theme
function colors.theme_set(theme)
    colors._THEME = theme
end

-- return module
return colors
