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
-- @file        border.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local view   = require("ui/view")
local label  = require("ui/label")
local curses = require("ui/curses")

-- define module
local border = border or view()

-- init border
function border:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

    -- check bounds
    assert(self:width() > 2 and self:height() > 2, string.format("%s: too small!", tostring(self)))
end

-- draw border
function border:on_draw(transparent)

    -- draw background (transparent)
    view.on_draw(self, true)

    -- get corner attribute
    local cornerattr = self:cornerattr()

    -- the left-upper attribute
    local attr_ul = curses.color_pair(cornerattr[1], self:background())
    if self:background() == cornerattr[1] then
        attr_ul = {attr_ul, "bold"}
    end

    -- the right-lower attribute
    local attr_rl = curses.color_pair(cornerattr[2], self:background())
    if self:background() == cornerattr[2] then
        attr_rl = {attr_rl, "bold"}
    end

    -- the border characters
    -- @note acs character will use 2 width on borders (pdcurses), so we use acsii characters instead of them.
    local iswin = os.host() == "windows"
    local hline = iswin and '-' or "hline"
    local vline = iswin and '|' or "vline"
    local ulcorner = iswin and ' ' or "ulcorner"
    local llcorner = iswin and ' ' or "llcorner"
    local urcorner = iswin and ' ' or "urcorner"
    local lrcorner = iswin and ' ' or "lrcorner"

    -- draw left and top border
    self:canvas():attr(attr_ul)
    self:canvas():move(0, 0):putchar(hline, self:width())
    self:canvas():move(0, 0):putchar(ulcorner)
    self:canvas():move(0, 1):putchar(vline, self:height() - 1, true)
    self:canvas():move(0, self:height() - 1):putchar(llcorner)

    -- draw bottom and right border
    self:canvas():attr(attr_rl)
    self:canvas():move(1, self:height() - 1):putchar(hline, self:width() - 1)
    self:canvas():move(self:width() - 1, 0):putchar(urcorner)
    self:canvas():move(self:width() - 1, 1):putchar(vline, self:height() - 1, true)
    self:canvas():move(self:width() - 1, self:height() - 1):putchar(lrcorner)
end

-- get border corner attribute
function border:cornerattr()
    return self._CORNERATTR or {"white", "black"}
end

-- set border corner attribute
function border:cornerattr_set(attr_ul, attr_rl)
    self._CORNERATTR = {attr_ul or "white", attr_rl or attr_ul or "black"}
    self:invalidate()
end

-- swap border corner attribute
function border:cornerattr_swap()
    local cornerattr = self:cornerattr()
    self:cornerattr_set(cornerattr[2], cornerattr[1])
end

-- return module
return border
