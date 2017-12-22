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
-- @file        desktop.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local view   = require("ui/view")
local group  = require("ui/group")
local curses = require("ui/curses")

-- define module
local desktop = desktop or group()

-- init desktop
function desktop:init(name, bounds)

    -- init group
    group.init(self, name, bounds)

    -- add background
    self:insert(self:background())
end

-- exit desktop
function desktop:exit()
    group.exit(self)
end

-- get desktop background
function desktop:background()

    -- init background
    if not self._BACKGROUND then

        -- create background view
        local background = view:new("desktop.background", rect {0, 0, self:width(), self:height()})
        self._BACKGROUND = background

        -- init background color
        background:attr_set("color", curses.color_pair("white", "blue"))

        -- draw background
        function background:draw()

            -- trace
            log:print("%s: draw ..", self)

            -- draw it
            local c = self:canvas()
            c:attr(self:attr("color")):move(0, 0):write(string.rep(' ', self:width() * self:height()))
        end
    end

    -- get background
    return self._BACKGROUND
end


-- return module
return desktop
