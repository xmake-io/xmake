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
-- @file        curses.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: core.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

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
        if char == 'block' then     return curses.ACS_BLOCK
    elseif char == 'board' then     return curses.ACS_BOARD
    elseif char == 'btee' then      return curses.ACS_BTEE
    elseif char == 'bullet' then    return curses.ACS_BULLET
    elseif char == 'ckboard' then   return curses.ACS_CKBOARD
    elseif char == 'darrow' then    return curses.ACS_DARROW
    elseif char == 'degree' then    return curses.ACS_DEGREE
    elseif char == 'diamond' then   return curses.ACS_DIAMOND
    elseif char == 'gequal' then    return curses.ACS_GEQUAL
    elseif char == 'hline' then     return curses.ACS_HLINE
    elseif char == 'lantern' then   return curses.ACS_LANTERN
    elseif char == 'larrow' then    return curses.ACS_LARROW
    elseif char == 'lequal' then    return curses.ACS_LEQUAL
    elseif char == 'llcorner' then  return curses.ACS_LLCORNER
    elseif char == 'lrcorner' then  return curses.ACS_LRCORNER
    elseif char == 'ltee' then      return curses.ACS_LTEE
    elseif char == 'nequal' then    return curses.ACS_NEQUAL
    elseif char == 'pi' then        return curses.ACS_PI
    elseif char == 'plminus' then   return curses.ACS_PLMINUS
    elseif char == 'plus' then      return curses.ACS_PLUS
    elseif char == 'rarrow' then    return curses.ACS_RARROW
    elseif char == 'rtee' then      return curses.ACS_RTEE
    elseif char == 's1' then        return curses.ACS_S1
    elseif char == 's3' then        return curses.ACS_S3
    elseif char == 's7' then        return curses.ACS_S7
    elseif char == 's9' then        return curses.ACS_S9
    elseif char == 'sterling' then  return curses.ACS_STERLING
    elseif char == 'ttee' then      return curses.ACS_TTEE
    elseif char == 'uarrow' then    return curses.ACS_UARROW
    elseif char == 'ulcorner' then  return curses.ACS_ULCORNER
    elseif char == 'urcorner' then  return curses.ACS_URCORNER
    elseif char == 'vline' then     return curses.ACS_VLINE
    elseif type(char) == 'string' and #char == 1 then
        return char
    else
        return ' '
    end
end

-- calculate attr from the attributes list
--
-- local attr = curses.calc_attr("yellow")
-- local attr = curses.calc_attr{ curses.color_pair("yellow", "green"), 'bold' }
--
function curses.calc_attr(attrs)

    -- curses.calc_attr(curses.A_BOLD)
    local atype = type(attrs)
    if atype == 'number' then
        return attrs
    -- curses.calc_attr("bold")
    elseif atype == 'string' then
        return curses.attr(attrs)
    -- curses.calc_attr{ curses.color_pair("yellow", "green"), 'bold' }
    elseif atype == 'table' then
        local v = 0
        local set = {}
        for _, a in ipairs(attrs) do 
            if not set[a] and a then
                set[a] = true
                if type(a) == 'number' then
                    v = v + a
                else
                    v = v + curses.attr(a)
                end
            end
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

    -- TODO rename
    -- get the color attr
    local attr = curses._color_pair(curses._NCOLORS)

    -- save to cache
    colors[key] = attr
    curses._COLORS = colors

    -- ok
    return attr
end

-- return module: curses
return curses
