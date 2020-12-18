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
-- @file        dialog.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local event  = require("ui/event")
local label  = require("ui/label")
local panel  = require("ui/panel")
local action = require("ui/action")
local button = require("ui/button")
local window = require("ui/window")
local curses = require("ui/curses")

-- define module
local dialog = dialog or window()

-- update the position of all buttons
function dialog:_update_buttons_layout()

    -- update the position of all buttons
    local index = 1
    local width = self:buttons():width()
    local count = self:buttons():count()
    local padding = math.floor(width / 8)
    for v in self:buttons():views() do
        local x = padding + index * math.floor((width - padding * 2) / (count + 1)) - math.floor(v:width() / 2)
        if x + v:width() > width then
            x = math.max(0, width - v:width())
        end
        v:bounds():move2(x, 0)
        v:invalidate(true)
        index = index + 1
    end
end

-- init dialog
function dialog:init(name, bounds, title)

    -- init window
    window.init(self, name, bounds, title, true)

    -- insert buttons
    self:panel():insert(self:buttons())
    self:panel():action_add(action.ac_on_resized, function (v)
        self:buttons():bounds_set(rect:new(0, v:height() - 1, v:width(), 1))
        self:_update_buttons_layout()
    end)

    -- mark as block mouse
    self:option_set("blockmouse", true)
end

-- get buttons
function dialog:buttons()
    if not self._BUTTONS then
        self._BUTTONS = panel:new("dialog.buttons", rect:new(0, self:panel():height() - 1, self:panel():width(), 1))
    end
    return self._BUTTONS
end

-- get button from the given button name
function dialog:button(name)
    return self:buttons():view(name)
end

-- add button
function dialog:button_add(name, text, command)

    -- init button
    local btn = button:new(name, rect:new(0, 0, #text, 1), text, command)

    -- insert button
    self:buttons():insert(btn)

    -- update the position of all buttons
    self:_update_buttons_layout()

    -- invalidate
    self:invalidate()

    -- ok
    return btn
end

-- select button from the given button name
function dialog:button_select(name)
    self:buttons():select(self:button(name))
    return self
end

-- quit dialog
function dialog:quit()
    local parent = self:parent()
    if parent then
        self:action_on(action.ac_on_exit)
        parent:remove(self)
    end
end

-- on event
function dialog:on_event(e)
    if e.type == event.ev_keyboard and e.key_name == "Esc" then
        self:quit()
        return true
    end
    return window.on_event(self, e)
end

-- return module
return dialog
