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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        window.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local label  = require("ui/label")
local panel  = require("ui/panel")
local curses = require("ui/curses")

-- define module
local window = window or panel()

-- init window
function window:init(name, bounds, title)

    -- init panel
    panel.init(self, name, bounds)

    -- check bounds
    assert(self:width() > 4 and self:height() > 3, string.format("%s: too small!", self))

    -- init background
    self:background_set("white")

    -- init title
    if title then
        self._TITLE = label:new("window.title", rect{0, 0, #title, 1}, title)
        self:title():textattr_set("blue bold")
        self:insert(self:title(), {centerx = true})
    end

    -- insert frame
    self:insert(self:frame())

    -- init shadow
    self:shadow_set("black")

    -- init border
    self:border_set({"white", "black"})
end

-- draw window
function window:draw()

    -- draw background
    panel.draw(self)

    -- draw shadow
    local shadow = self:shadow()
    if shadow then
        local parent = assert(self:parent())
        self:canvas():attr(curses.color_pair(parent:background(), parent:background()))
        self:canvas():move(0, self:height() - 1):putchar(' ', 2)
        self:canvas():move(self:width() - 2, 0):putchar(' ', 2)
        self:canvas():attr(curses.color_pair(shadow, shadow))
        self:canvas():move(2, self:height() - 1):putchar(' ', self:width() - 2)
        self:canvas():move(self:width() - 2, 1):putchar(' ', self:height() - 1, true)
        self:canvas():move(self:width() - 1, 1):putchar(' ', self:height() - 1, true)
    end

    -- draw border
    local border = self:border()
    if border then
        local fbounds = self:frame():bounds()

        -- draw left and top border
        self:canvas():attr({curses.color_pair(border[1], self:frame():background()), "standout"})
        self:canvas():move(0, 0):putchar("hline", fbounds.ex)
        self:canvas():move(0, 0):putchar("ulcorner")
        self:canvas():move(0, 1):putchar("vline", fbounds.ey - 1, true)
        self:canvas():move(0, fbounds.ey):putchar("llcorner")

        -- draw bottom and right border
        self:canvas():attr(curses.color_pair(border[2], self:frame():background()))
        self:canvas():move(1, fbounds.ey):putchar("hline", fbounds.ex)
        self:canvas():move(fbounds.ex, 0):putchar("urcorner")
        self:canvas():move(fbounds.ex, 1):putchar("vline", fbounds.ey - 1, true)
        self:canvas():move(fbounds.ex, fbounds.ey):putchar("lrcorner")
    end

    -- draw title
    if self:title() then
        label.draw(self:title())
    end
end

-- get frame
function window:frame()
    if not self._FRAME then
        self._FRAME = panel:new("window.panel", rect{0, 0, self:width(), self:height()})
    end
    return self._FRAME
end

-- get title
function window:title()
    return self._TITLE
end

-- get shadow 
function window:shadow()
    return self._SHADOW
end

-- set shadow
function window:shadow_set(shadow)
    if not self._SHADOW and shadow then
        self:frame():bounds():movee(-2, -1)
    elseif self._SHADOW and not shadow then
        self:frame():bounds():movee(2, 1)
    end
    self._SHADOW = shadow
    self:invalidate()
end

-- get border 
function window:border()
    return self._BORDER
end

-- set border
function window:border_set(border)
    if not self._BORDER and border then
        self:frame():bounds():grow(-1, -1)
    elseif self._BORDER and not border then
        self:frame():bounds():grow(1, 1)
    end
    self._BORDER = border
    self:invalidate()
end

-- return module
return window
