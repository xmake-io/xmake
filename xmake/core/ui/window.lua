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
-- @file        window.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local label  = require("ui/label")
local panel  = require("ui/panel")
local curses = require("ui/curses")

-- define module
local window = window or panel()

-- init window
function window:init(name, bounds, title)

    -- init panel
    panel.init(self, name, bounds)

    -- TODO check bounds

    -- init title
    if title then
        self._TITLE = label:new("window.title", rect{0, 0, #title, 1}, title)
        self:title():textattr_set("blue bold")
    end

    -- insert frame
    self:insert(self:frame())
end

-- draw window
function window:draw()

    -- draw background
    panel.draw(self)

    -- draw shadow
    local shadow = curses.color_pair("black", "black")
    self:canvas():attr(shadow):move(2, self:height() - 1):write(string.rep(' ', self:width() - 2))
    for y = 1, self:height() - 1 do
        self:canvas():move(self:width() - 2, y):write('  ')
    end

    -- TODO draw line
    -- draw border
    local border = curses.color_pair("black", "white")
    self:canvas():attr(border):move(0, self:height() - 2):write(' ')
    self:canvas():move(1, self:height() - 2):write(string.rep('-', self:width() - 4))
    self:canvas():move(self:width() - 3, 0):write('-')
    for y = 1, self:height() - 2 do
        self:canvas():move(self:width() - 3, y):write('|')
    end
end

-- get frame
function window:frame()
    if not self._FRAME then
        self._FRAME = panel:new("window.panel", rect{0, 0, self:width() - 3, self:height() - 2})
        self._FRAME:background_set("white")
        self._FRAME:insert(self:title(), {centerx = true})
    end
    return self._FRAME
end

-- get title
function window:title()
    return self._TITLE
end

-- return module
return window
