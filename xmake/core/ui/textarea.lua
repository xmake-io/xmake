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
-- @file        textarea.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local label     = require("ui/label")
local event     = require("ui/event")
local curses    = require("ui/curses")
local action    = require("ui/action")

-- define module
local textarea = textarea or label()

-- init textarea
function textarea:init(name, bounds, text)

    -- init label
    label.init(self, name, bounds, text)

    -- mark as selectable
    self:option_set("selectable", true)

    -- init start line
    self._STARTLINE = 0
    self._LINECOUNT = 0
end

-- draw textarea
function textarea:on_draw(transparent)

    -- draw background
    view.on_draw(self, transparent)

    -- get the text attribute value
    local textattr = self:textattr_val()

    -- draw text string
    local strs = self._SPLITTEXT
    if strs and #strs > 0 and textattr then
        self:canvas():attr(textattr):move(0, 0):putstrs(strs, self._STARTLINE + 1)
    end
end

-- set text
function textarea:text_set(text)
    self._STARTLINE = 0
    self._SPLITTEXT = text and self:splitext(text) or {}
    self._LINECOUNT = #self._SPLITTEXT
    return label.text_set(self, text)
end

-- is scrollable?
function textarea:scrollable()
    return self._LINECOUNT > self:height()
end

-- scroll
function textarea:scroll(lines)
    if self:scrollable() then
        self._STARTLINE = self._STARTLINE + lines
        if self._STARTLINE < 0 then
            self._STARTLINE = 0
        end
        local startline_end = self._LINECOUNT > self:height() and self._LINECOUNT - self:height() or self._LINECOUNT
        if self._STARTLINE > startline_end then
            self._STARTLINE = startline_end
        end
        self:action_on(action.ac_on_scrolled, self._STARTLINE / startline_end)
        self:invalidate()
    end
end

-- scroll to end
function textarea:scroll_to_end()
    if self:scrollable() then
        local startline_end = self._LINECOUNT > self:height() and self._LINECOUNT - self:height() or self._LINECOUNT
        self._STARTLINE = startline_end
        self:action_on(action.ac_on_scrolled, self._STARTLINE / startline_end)
        self:invalidate()
    end
end

-- on event
function textarea:on_event(e)
    if e.type == event.ev_keyboard then
        if e.key_name == "Up" then
            self:scroll(-5)
            return true
        elseif e.key_name == "Down" then
            self:scroll(5)
            return true
        end
    end
end

-- return module
return textarea
