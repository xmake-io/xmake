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

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: statusbar.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local view      = require("ui/view")
local curses    = require("ui/curses")

-- define module
local statusbar = statusbar or view()

-- init statusbar
function statusbar:init(name, bounds)
    view.init(self, name, bounds)
end

-- exit statusbar
function statusbar:exit()
    view.exit(self)
end

-- draw view
function statusbar:draw()

    -- get canvas
    local c = self:canvas()
    c:move(0, 0)

    -- draw statusbar
    local x = 0
    local color = self:attr("color")
    if x < self:width() then
        c:attr(color):write(string.rep(' ', self:width() - x))
    end
end

-- do event
function statusbar:do_event(e)
    view.do_event(self, e)
end

-- return module
return statusbar
