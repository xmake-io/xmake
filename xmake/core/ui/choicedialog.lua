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
-- @file        choicedialog.lua
--

-- load modules
local log         = require("ui/log")
local rect        = require("ui/rect")
local event       = require("ui/event")
local action      = require("ui/action")
local curses      = require("ui/curses")
local window      = require("ui/window")
local choicebox   = require("ui/choicebox")
local boxdialog   = require("ui/boxdialog")

-- define module
local choicedialog = choicedialog or boxdialog()

-- init dialog
function choicedialog:init(name, bounds, title)

    -- init window
    boxdialog.init(self, name, bounds, title)

    -- init text
    self:text():text_set("Use the arrow keys to navigate this window or press the hotkey of the item you wish to select followed by the <SPACEBAR>. Press <?> for additional information about this")

    -- init buttons
    self:button_add("select", "< Select >", function (v, e)
        self:choicebox():on_event(event.command {"cm_enter"})
        self:quit()
    end)
    self:button_add("cancel", "< Cancel >", function (v, e)
        self:quit()
    end)
    self:buttons():select(self:button("select"))

    -- insert choice box
    self:box():panel():insert(self:choicebox())

    -- disable to select to box (disable Tab switch and only response to buttons)
    self:box():option_set("selectable", false)
end

-- get choice box
function choicedialog:choicebox()
    if not self._CHOICEBOX then
        local bounds = self:box():panel():bounds()
        self._CHOICEBOX = choicebox:new("choicedialog.choicebox", rect:new(0, 0, bounds:width(), bounds:height()))
        self._CHOICEBOX:state_set("focused", true) -- we can select and highlight selected item
    end
    return self._CHOICEBOX
end

-- on event
function choicedialog:on_event(e)

    -- load values first
    if e.type == event.ev_idle then
        if not self._LOADED then
            self:action_on(action.ac_on_load)
            self._LOADED = true
        end
    -- select value
    elseif e.type == event.ev_keyboard then
        if e.key_name == "Down" or e.key_name == "Up" or e.key_name == " " then
            return self:choicebox():on_event(e)
        end
    end
    return boxdialog.on_event(self, e)
end

-- return module
return choicedialog
