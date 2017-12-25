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
-- @file        statusbar.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local event     = require("ui/event")
local curses    = require("ui/curses")

-- define module
local statusbar = statusbar or view()

-- init statusbar
function statusbar:init(name, bounds, commands)

    -- init view
    view.init(self, name, bounds)

    -- init info
    self:info_set("")

    -- init background
    self:background_set(curses.color_pair("blue", "white"))
end

-- exit statusbar
function statusbar:exit()
    view.exit(self)
end

-- draw view
function statusbar:draw()

    -- draw background
    view.draw(self)

    -- draw status info
    self:canvas():move(1, 0):write(self:info())
end

-- on event
function statusbar:event_on(e)
    view.event_on(self, e)
end

-- get status info
function statusbar:info()
    return self._INFO
end

-- set status info
function statusbar:info_set(info)
    self._INFO = info or ""
    self:invalidate()
end

-- return module
return statusbar
