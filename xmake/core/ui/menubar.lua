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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        menubar.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: menubar.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local curses    = require("ui/curses")

-- define module
local menubar = menubar or view()

-- init menubar
function menubar:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

    -- init title
    self._TITLE = "Menu Bar"

    -- init color
    self:attr_set("color", curses.color_pair("red", "white"))
end

-- exit menubar
function menubar:exit()
    view.exit(self)
end

-- draw view
function menubar:draw()

    -- trace
    log:print("%s: draw ..", self)

    -- draw it
    local c = self:canvas()
    c:attr(self:attr("color")):move(0, 0):write(string.rep(' ', self:width() * self:height()))
    c:move(1, 0):write(self:title())
end

-- en event
function menubar:event_on(e)
    view.event_on(self, e)
end

-- get title
function menubar:title()
    return self._TITLE
end

-- set title
function menubar:title_set(title)
    self._TITLE = title or ""
end

-- return module
return menubar
