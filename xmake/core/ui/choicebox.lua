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
-- @file        choicebox.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local rect      = require("ui/rect")
local panel     = require("ui/panel")
local event     = require("ui/event")
local action    = require("ui/action")
local curses    = require("ui/curses")
local button    = require("ui/button")
local object    = require("ui/object")

-- define module
local choicebox = choicebox or panel()

-- init choicebox
function choicebox:init(name, bounds)

    -- init panel
    panel.init(self, name, bounds)

    -- init values
    self._VALUES = {}
end

-- on event
function choicebox:on_event(e)

    -- select config
    if e.type == event.ev_keyboard then
        if e.key_name == "Down" then
            return self:select_next()
        elseif e.key_name == "Up" then
            return self:select_prev()
        elseif e.key_name == "Enter" or e.key_name == " " then
            self:_do_select()
            return true
        end
    elseif e.type == event.ev_command and e.command == "cm_enter" then
        self:_do_select()
        return true
    end
end

-- load values
function choicebox:load(values, selected)

    -- clear the views first
    self:clear()

    -- insert values
    self._VALUES = values
    for idx, value in ipairs(values) do
        self:_do_insert(value, idx, idx == selected)
    end

    -- select the first item
    self:select(self:first())

    -- invalidate
    self:invalidate()
end

-- do insert a value item
function choicebox:_do_insert(value, index, selected)

    -- init text
    local text = (selected and "(X) " or "( ) ") .. tostring(value)

    -- init a value item view
    local item = button:new("choicebox.value." .. self:count(), rect:new(0, self:count(), self:width(), 1), text)

    -- attach this index
    item:extra_set("index", index)

    -- insert this config item
    self:insert(item)
end

-- do select the current config
function choicebox:_do_select()

    -- get the current item
    local item = self:current()

    -- get the current index
    local index = item:extra("index")

    -- get the current value
    local value = self._VALUES[index]

    -- do action: on selected
    self:action_on(action.ac_on_selected, index, value)

    -- update text
    item:text_set("(X) " .. tostring(value))
end

-- return module
return choicebox
