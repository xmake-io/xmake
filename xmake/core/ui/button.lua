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
-- @file        button.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local event     = require("ui/event")
local label     = require("ui/label")
local curses    = require("ui/curses")

-- define module
local button = button or label()

-- init button
function button:init(name, bounds, text, action)

    -- init label
    label.init(self, name, bounds, text)

    -- mark as selectable
    self:option_set("selectable", true)

    -- show cursor
    self:cursor_show(true)

    -- init action
    self:action_set("on_enter", action)
end

-- draw button
function button:draw()

    -- draw background
    view.draw(self)

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
    if self:state("selected") then
        textattr = {textattr, "reverse"}
    end

    -- draw text
    self:canvas():attr(textattr):move(0, 0):puts(str)
end

-- on event
function button:event_on(e)

    -- selected?
    if not self:state("selected") then
        return 
    end

    -- enter this button?
    if e.type == event.ev_keyboard then
        if e.key_name == "Enter" then
            local on_enter = self:action("on_enter")
            if on_enter then
                if type(on_enter) == "string" then
                    -- send command
                    self:application():send(on_enter)
                elseif type(on_enter) == "function" then
                    -- do enter script
                    on_enter(self)
                end
            end
            return true
        end
    end
end

-- return module
return button
