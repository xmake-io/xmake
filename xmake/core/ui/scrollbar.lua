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
-- @file        scrollbar.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local event     = require("ui/event")
local curses    = require("ui/curses")
local action    = require("ui/action")

-- define module
local scrollbar = scrollbar or view()

-- init scrollbar
function scrollbar:init(name, bounds, vertical)

    -- init view
    view.init(self, name, bounds)

    -- init bar attribute
    self:charattr_set("black on black")

    -- init bar vertical
    self:vertical_set(vertical)

    -- init progress
    self:progress_set(0)

    -- init character
    self:char_set(' ')
end

-- get bar attribute
function scrollbar:charattr()
    return self:attr("charattr")
end

-- set bar attribute, .e.g charattr_set("yellow onblue bold")
function scrollbar:charattr_set(attr)
    return self:attr_set("charattr", attr)
end

-- get the current char attribute value
function scrollbar:charattr_val()

    -- get text attribute
    local charattr = self:charattr()
    if not charattr then
        return
    end

    -- no text background? use view's background
    if self:background() and not charattr:find("on") then
        charattr = charattr .. " on" .. self:background()
    end

    -- attempt to get the attribute value from the cache first
    self._charattr = self._charattr or {}
    local value = self._charattr[charattr]
    if value then
        return value
    end

    -- update the cache
    value = curses.calc_attr(charattr:split("%s+"))
    self._charattr[charattr] = value
    return value
end

-- get bar character
function scrollbar:char()
    return self:attr("char") or ' '
end

-- set bar character
function scrollbar:char_set(char)
    if char ~= self:char() then
        self:invalidate()
    end
    return self:attr_set("char", char)
end

-- is vertical bar?
function scrollbar:vertical()
    return self:attr("vertical") or true
end

-- set bar vertical
function scrollbar:vertical_set(vertical)
    return self:attr_set("vertical", vertical)
end

-- get bar progress
function scrollbar:progress()
    return self:attr("progress") or 0
end

-- set bar progress, [0, 1]
function scrollbar:progress_set(progress)
    if progress > 1 then
        progress = 1
    elseif progress < 0 then
        progress = 0
    end
    if progress ~= self:progress() then
        self:invalidate()
    end
    return self:attr_set("progress", progress)
end

-- get bar step width
function scrollbar:stepwidth()
    return self:attr("stepwidth") or 0.1
end

-- set bar step width, [0, 1]
function scrollbar:stepwidth_set(stepwidth)
    if stepwidth > 1 then
        stepwidth = 1
    elseif stepwidth < 0 then
        stepwidth = 0
    end
    if stepwidth ~= self:stepwidth() then
        self:invalidate()
    end
    return self:attr_set("stepwidth", stepwidth)
end

-- draw scrollbar
function scrollbar:on_draw(transparent)

    -- draw background
    view.on_draw(self, transparent)

    -- draw bar
    local char      = self:char()
    local charattr  = self:charattr_val()
    if self:vertical() then
        local sn = math.ceil(self:height() * self:stepwidth())
        local sb = math.floor(self:height() * self:progress())
        local se = sb + sn
        if se > self:height() then
            sb = self:height() - sn
            se = self:height()
        end
        if se > sb and se - sb <= self:height() then
            for x = 0, self:width() - 1 do
                self:canvas():attr(charattr):move(x, sb):putchar(char, se - sb, true)
            end
        end
    else
        local sn = math.ceil(self:width() * self:stepwidth())
        local sb = math.floor(self:width() * self:progress())
        local se = sb + sn
        if se > self:width() then
            sb = self:width() - sn
            se = self:width()
        end
        if se > sb and se - sb <= self:width() then
            for y = 0, self:height() - 1 do
                self:canvas():attr(charattr):move(sb, y):putchar(char, se - sb)
            end
        end
    end
end

-- scroll bar, e.g. -1 * 0.1, 1 * 0.1
function scrollbar:scroll(steps)
    steps = steps or 1
    self:progress_set(self:progress() + steps * self:stepwidth())
    self:action_on(action.ac_on_scrolled, self:progress())
end

-- on event
function scrollbar:on_event(e)
    if e.type == event.ev_keyboard then
        if self:vertical() then
            if e.key_name == "Up" then
                self:scroll(-1)
                return true
            elseif e.key_name == "Down" then
                self:scroll(1)
                return true
            end
        else
            if e.key_name == "Left" then
                self:scroll(-1)
                return true
            elseif e.key_name == "Right" then
                self:scroll(1)
                return true
            end
        end
    end
end

-- return module
return scrollbar
