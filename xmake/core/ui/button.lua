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
-- @file        button.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local event     = require("ui/event")
local label     = require("ui/label")
local action    = require("ui/action")
local curses    = require("ui/curses")

-- define module
local button = button or label()

-- init button
function button:init(name, bounds, text, on_action)

    -- init label
    label.init(self, name, bounds, text)

    -- mark as selectable
    self:option_set("selectable", true)

    -- show cursor
    self:cursor_show(true)

    -- init actions
    self:option_set("mouseable", true)
    self:action_set(action.ac_on_enter, on_action)
    self:action_set(action.ac_on_clicked, function (v)
        v:action_on(action.ac_on_enter)
        return true
    end)
end

-- draw button
function button:on_draw(transparent)

    -- draw background
    view.on_draw(self, transparent)

    -- strip text string
    local str = self:text()
    if str and #str > 0 then
        str = string.sub(str, 1, self:width())
    end
    if not str or #str == 0 then
        return
    end

    -- get the text attribute value
    local textattr = self:textattr_val()

    -- selected?
    if self:state("selected") and self:state("focused") then
        textattr = {textattr, "reverse"}
    end

    -- draw text
    self:canvas():attr(textattr):move(0, 0):putstr(str)
end

-- on event
function button:on_event(e)

    -- selected?
    if not self:state("selected") then
        return
    end

    -- enter this button?
    if e.type == event.ev_keyboard then
        if e.key_name == "Enter" then
            self:action_on(action.ac_on_enter)
            return true
        end
    end
end

-- set state
function button:state_set(name, enable)
    if name == "focused" and self:state(name) ~= enable then
        self:invalidate()
    end
    return view.state_set(self, name, enable)
end

-- return module
return button
