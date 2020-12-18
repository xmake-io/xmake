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
-- @file        canvas.lua
--

-- load modules
local log    = require("ui/log")
local point  = require("ui/point")
local object = require("ui/object")
local curses = require("ui/curses")

-- define module
local line   = line or object()
local canvas = canvas or object()

-- new canvas instance
function canvas:new(view, window)

    -- create instance
    self = self()

    -- save view and window
    self._view = view
    self._window = window
    assert(view and window, "cannot new canvas instance without view and window!")

    -- set the default attributes
    self:attr()

    -- done
    return self
end

-- clear canvas
function canvas:clear()
    self._window:clear()
    return self
end

-- move canvas to the given position
function canvas:move(x, y)
    self._window:move(y, x)
    return self
end

-- get the current position
function canvas:pos()
    local y, x = self._window:getyx()
    return x, y
end

-- get the canvas size
function canvas:size()
    local y, x = self._window:getmaxyx()
    return point {x + 1, y + 1}
end

-- get the canvas width
function canvas:width()
    local _, x = self._window:getmaxyx()
    return x + 1
end

-- get the canvas height
function canvas:height()
    local y, _ = self._window:getmaxyx()
    return y + 1
end

-- put character to canvas
function canvas:putchar(ch, n, vertical)

    -- acs character?
    if type(ch) == "string" and #ch > 1 then
        ch = curses.acs(ch)
    end

    -- draw characters
    n = n or 1
    if vertical then
        local x, y = self:pos()
        while n > 0 do
            self:move(x, y)
            self._window:addch(ch)
            n = n - 1
            y = y + 1
        end
    else
        while n > 0 do
            self._window:addch(ch)
            n = n - 1
        end
    end
    return self
end

-- put a string to canvas
function canvas:putstr(str)
    self._window:addstr(str)
    return self
end

-- put strings to canvas
function canvas:putstrs(strs, startline)

    -- draw strings
    local sy, sx = self._window:getyx()
    local ey, _ = self._window:getmaxyx()
    for idx = startline or 1, #strs do
        local _, y = self:pos()
        self._window:addstr(strs[idx])
        if y + 1 < ey and idx < #strs then
            self:move(sx, y + 1)
        else
            break
        end
    end
    return self
end

-- set canvas attributes
--
-- set attr:    canvas:attr("bold")
-- add attr:    canvas:attr("bold", true)
-- remove attr: canvas:attr("bold", false)
--
function canvas:attr(attrs, modify)

    -- calculate the attributes
    local attr = curses.calc_attr(attrs)
    if modify == nil then
        self._window:attrset(attr)
    elseif modify == false then
        self._window:attroff(attr)
    else
        self._window:attron(attr)
    end
    return self
end

-- return module
return canvas
