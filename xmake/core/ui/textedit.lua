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
-- @file        textedit.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local label     = require("ui/label")
local event     = require("ui/event")
local border    = require("ui/border")
local curses    = require("ui/curses")

-- define module
local textedit = textedit or label()

-- init textedit
function textedit:init(name, bounds, text)

    -- init label
    label.init(self, name, bounds, text)

    -- show cursor
    self:cursor_show(true)

    -- mark as selectable
    self:option_set("selectable", true)
end

-- draw textedit
function textedit:draw(transparent)

    -- draw label
    label.draw(self, transparent)

    -- TODO
    -- move cursor
    local x, y = self:canvas():pos()
    self:cursor_move(x, y)
end

-- on event
function textedit:event_on(e)

    -- update text
    if e.type == event.ev_keyboard then
        if e.key_code > 0x1f and e.key_code < 0x7f then
            self:text_set(self:text() .. e.key_name)
        elseif e.key_name == "Enter" then
            self:text_set(self:text() .. '\n')
        elseif e.key_name == "Backspace" then
            local text = self:text()
            if #text > 0 then
                self:text_set(text:sub(1, #text - 1))
            end
        end
    end
end

-- return module
return textedit
