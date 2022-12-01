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
-- @file        curses.lua
--

-- define module: curses
local curses = curses or {}

-- load modules
local os  = require("base/os")
local log = require("ui/log")

-- get color from the given name
function curses.color(name)
        if name == 'black' then     return curses.COLOR_BLACK
    elseif name == 'red' then       return curses.COLOR_RED
    elseif name == 'green' then     return curses.COLOR_GREEN
    elseif name == 'yellow' then    return curses.COLOR_YELLOW
    elseif name == 'blue' then      return curses.COLOR_BLUE
    elseif name == 'magenta' then   return curses.COLOR_MAGENTA
    elseif name == 'cyan' then      return curses.COLOR_CYAN
    elseif name == 'white' then     return curses.COLOR_WHITE
    else                            return curses.COLOR_BLACK
    end
end

-- is color?
local colors = {black = true, red = true, green = true, yellow = true, blue = true, magenta = true, cyan = true, white = true}
function curses.iscolor(name)
    return colors[name] or colors[name:sub(3) or ""]
end

-- get attr from the given name
function curses.attr(name)
        if name == 'normal' then    return curses.A_NORMAL
    elseif name == 'standout' then  return curses.A_STANDOUT
    elseif name == 'underline' then return curses.A_UNDERLINE
    elseif name == 'reverse' then   return curses.A_REVERSE
    elseif name == 'blink' then     return curses.A_BLINK
    elseif name == 'dim' then       return curses.A_DIM
    elseif name == 'bold' then      return curses.A_BOLD
    elseif name == 'protect' then   return curses.A_PROTECT
    elseif name == 'invis' then     return curses.A_INVIS
    elseif name == 'alt' then       return curses.A_ALTCHARSET
    else                            return curses.A_NORMAL
    end
end

-- get acs character from the given name
function curses.acs(name)
        if name == 'block' then     return curses.ACS_BLOCK
    elseif name == 'board' then     return curses.ACS_BOARD
    elseif name == 'btee' then      return curses.ACS_BTEE
    elseif name == 'bullet' then    return curses.ACS_BULLET
    elseif name == 'ckboard' then   return curses.ACS_CKBOARD
    elseif name == 'darrow' then    return curses.ACS_DARROW
    elseif name == 'degree' then    return curses.ACS_DEGREE
    elseif name == 'diamond' then   return curses.ACS_DIAMOND
    elseif name == 'gequal' then    return curses.ACS_GEQUAL
    elseif name == 'hline' then     return curses.ACS_HLINE
    elseif name == 'lantern' then   return curses.ACS_LANTERN
    elseif name == 'larrow' then    return curses.ACS_LARROW
    elseif name == 'lequal' then    return curses.ACS_LEQUAL
    elseif name == 'llcorner' then  return curses.ACS_LLCORNER
    elseif name == 'lrcorner' then  return curses.ACS_LRCORNER
    elseif name == 'ltee' then      return curses.ACS_LTEE
    elseif name == 'nequal' then    return curses.ACS_NEQUAL
    elseif name == 'pi' then        return curses.ACS_PI
    elseif name == 'plminus' then   return curses.ACS_PLMINUS
    elseif name == 'plus' then      return curses.ACS_PLUS
    elseif name == 'rarrow' then    return curses.ACS_RARROW
    elseif name == 'rtee' then      return curses.ACS_RTEE
    elseif name == 's1' then        return curses.ACS_S1
    elseif name == 's3' then        return curses.ACS_S3
    elseif name == 's7' then        return curses.ACS_S7
    elseif name == 's9' then        return curses.ACS_S9
    elseif name == 'sterling' then  return curses.ACS_STERLING
    elseif name == 'ttee' then      return curses.ACS_TTEE
    elseif name == 'uarrow' then    return curses.ACS_UARROW
    elseif name == 'ulcorner' then  return curses.ACS_ULCORNER
    elseif name == 'urcorner' then  return curses.ACS_URCORNER
    elseif name == 'vline' then     return curses.ACS_VLINE
    elseif type(name) == 'string' and #name == 1 then
        return name
    else
        return ' '
    end
end

-- calculate attr from the attributes list
--
-- local attr = curses.calc_attr("bold")
-- local attr = curses.calc_attr("yellow")
-- local attr = curses.calc_attr{ "yellow", "ongreen" }
-- local attr = curses.calc_attr{ "yellow", "ongreen", "bold" }
-- local attr = curses.calc_attr{ curses.color_pair("yellow", "green"), "bold" }
--
function curses.calc_attr(attrs)

    -- curses.calc_attr(curses.A_BOLD)
    -- curses.calc_attr(curses.color_pair("yellow", "green"))
    local atype = type(attrs)
    if atype == "number" then
        return attrs
    -- curses.calc_attr("bold")
    -- curses.calc_attr("yellow")
    elseif atype == "string" then
        if curses.iscolor(attrs) then
            local color = attrs
            if color:startswith("on") then
                color = color:sub(3)
            end
            return curses.color_pair(color, color)
        end
        return curses.attr(attrs)
    -- curses.calc_attr{ "yellow", "ongreen", "bold" }
    -- curses.calc_attr{ curses.color_pair("yellow", "green"), "bold" }
    elseif atype == "table" then
        local v = 0
        local set = {}
        local fg = nil
        local bg = nil
        for _, a in ipairs(attrs) do
            if not set[a] and a then
                set[a] = true
                if type(a) == "number" then
                    v = v + a
                elseif curses.iscolor(a) then
                    if a:startswith("on") then
                        bg = a:sub(3)
                    else
                        fg = a
                    end
                else
                    v = v + curses.attr(a)
                end
            end
        end
        if fg or bg then
            v = v + curses.color_pair(fg or bg, bg or fg)
        end
        return v
    else
        return 0
    end
end

-- get attr from the color pair
curses._color_pair = curses._color_pair or curses.color_pair
function curses.color_pair(fg, bg)

    -- get foreground and backround color
    fg = curses.color(fg)
    bg = curses.color(bg)

    -- attempt to get color from the cache first
    local key = fg .. ':' .. bg
    local colors = curses._COLORS or {}
    if colors[key] then
        return colors[key]
    end

    -- no colors?
    if not curses.has_colors() then
        return 0
    end

    -- update the colors count
    curses._NCOLORS = (curses._NCOLORS or 0) + 1

    -- init the color pair
    if not curses.init_pair(curses._NCOLORS, fg, bg) then
        os.raise("failed to initialize color pair (%d, %s, %s)", curses._NCOLORS, fg, bg)
    end

    -- get the color attr
    local attr = curses._color_pair(curses._NCOLORS)

    -- save to cache
    colors[key] = attr
    curses._COLORS = colors

    -- ok
    return attr
end

-- set cursor state
curses._cursor_set = curses._cursor_set or curses.cursor_set
function curses.cursor_set(state)
    if curses._CURSOR_STATE ~= state then
        curses._CURSOR_STATE = state
        curses._cursor_set(state)
    end
end

-- has mouse?
function curses.has_mouse()
    return curses.KEY_MOUSE and true or false
end

-- return module: curses
return curses
