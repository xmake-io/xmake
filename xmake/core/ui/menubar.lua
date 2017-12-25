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
    self:title_set("Menu Bar")

    -- init background
    self:background_set(curses.color_pair("red", "white"))
end

-- exit menubar
function menubar:exit()
    view.exit(self)
end

-- draw view
function menubar:draw()

    -- draw background
    view.draw(self)

    -- draw it
    self:canvas():move(1, 0):write(self:title())
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
    self:invalidate()
end

-- return module
return menubar
