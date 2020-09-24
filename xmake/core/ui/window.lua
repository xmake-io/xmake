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
-- @author      ruki
-- @file        window.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local view   = require("ui/view")
local label  = require("ui/label")
local panel  = require("ui/panel")
local event  = require("ui/event")
local border = require("ui/border")
local curses = require("ui/curses")
local action = require("ui/action")

-- define module
local window = window or panel()

-- init window
function window:init(name, bounds, title, shadow)

    -- init panel
    panel.init(self, name, bounds)

    -- check bounds
    assert(self:width() > 4 and self:height() > 3, string.format("%s: too small!", tostring(self)))

    -- insert shadow
    if shadow then
        self._SHADOW = view:new("window.shadow", rect{2, 1, self:width(), self:height()}):background_set("black")
        self:insert(self:shadow())
        self:frame():bounds():movee(-2, -1)
        self:frame():invalidate(true)
    end

    -- insert border
    self:frame():insert(self:border())

    -- insert title
    if title then
        self._TITLE = label:new("window.title", rect{0, 0, #title, 1}, title)
        self:title():textattr_set("blue bold")
        self:title():action_set(action.ac_on_text_changed, function (v)
            if v:text() then
                local bounds = v:bounds()
                v:bounds():resize(#v:text(), v:height())
                bounds:move2(math.max(0, math.floor((self:frame():width() - v:width()) / 2)), bounds.sy)
                v:invalidate(true)
            end
        end)
        self:frame():insert(self:title(), {centerx = true})
    end

    -- insert panel
    self:frame():insert(self:panel())

    -- insert frame
    self:insert(self:frame())
end

-- get frame
function window:frame()
    if not self._FRAME then
        self._FRAME = panel:new("window.frame", rect{0, 0, self:width(), self:height()}):background_set("white")
    end
    return self._FRAME
end

-- get panel
function window:panel()
    if not self._PANEL then
        self._PANEL = panel:new("window.panel", self:frame():bounds())
        self._PANEL:bounds():grow(-1, -1)
        self._PANEL:invalidate(true)
    end
    return self._PANEL
end

-- get title
function window:title()
    return self._TITLE
end

-- get shadow
function window:shadow()
    return self._SHADOW
end

-- get border
function window:border()
    if not self._BORDER then
        self._BORDER = border:new("window.border", self:frame():bounds())
    end
    return self._BORDER
end

-- on event
function window:on_event(e)

    -- select panel?
    if e.type == event.ev_keyboard then
        if e.key_name == "Tab" then
            return self:panel():select_next()
        end
    end
end

-- on resize
function window:on_resize()
    self:frame():bounds_set(rect{0, 0, self:width(), self:height()})
    if self:shadow() then
        self:shadow():bounds_set(rect{2, 1, self:width(), self:height()})
        self:frame():bounds():movee(-2, -1)
    end
    self:border():bounds_set(self:frame():bounds())
    if self:title() then
        self:frame():center(self:title(), {centerx = true})
    end
    self:panel():bounds_set(self:frame():bounds())
    self:panel():bounds():grow(-1, -1)
    panel.on_resize(self)
end

-- return module
return window
