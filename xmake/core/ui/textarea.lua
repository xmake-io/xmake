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
-- @file        textarea.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local label     = require("ui/label")
local event     = require("ui/event")
local curses    = require("ui/curses")

-- define module
local textarea = textarea or label()

-- init textarea
function textarea:init(name, bounds, text)

    -- init label
    label.init(self, name, bounds, text)

    -- mark as selectable
    self:option_set("selectable", true)

    -- enable progress
    self:option_set("progress", true)

    -- init start line
    self._STARTLINE = 0
    self._LINECOUNT = 0
end

-- draw textarea
function textarea:draw(transparent)

    -- draw background
    view.draw(self, transparent)

    -- get the text attribute value
    local textattr = self:textattr_val()

    -- draw text string
    local strs = self._SPLITTEXT
    if strs and #strs > 0 and textattr then
        self:canvas():attr(textattr):move(0, 0):putstrs(strs, self._STARTLINE + 1)
    end

    -- draw progress
    if self:option("progress") then
        local progress = (self._STARTLINE + math.min(self:height(), self._LINECOUNT)) * 100 / self._LINECOUNT
        if (self._STARTLINE > 0 or progress < 100) and self:width() > 20 then
            self:canvas():move(self:width() - 10, self:height() - 1):putstr(string.format("(%%%d)", progress))
        end
    end
end

-- set text
function textarea:text_set(text)
    self._STARTLINE = 0
    self._SPLITTEXT = text and self:splitext(text) or {}
    self._LINECOUNT = #self._SPLITTEXT
    return label.text_set(self, text)
end

-- scroll
function textarea:scroll(lines)
    if self._LINECOUNT > self:height() then
        self._STARTLINE = self._STARTLINE + lines
        if self._STARTLINE < 0 then
            self._STARTLINE = 0
        end
        if self._STARTLINE > self._LINECOUNT - self:height() then
            self._STARTLINE = self._LINECOUNT - self:height() 
        end
        self:invalidate()
    end
end

-- scroll to end
function textarea:scroll_to_end()
    if self._LINECOUNT > self:height() then
        self._STARTLINE = self._LINECOUNT - self:height() 
        self:invalidate()
    end
end

-- on event
function textarea:event_on(e)
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
