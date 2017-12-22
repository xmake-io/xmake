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
local log   = require("ui/log")
local group = require("ui/group")

-- define module
local desktop = desktop or group()

-- init desktop
function desktop:init(name, bounds)

    -- init group
    group.init(self, name, bounds)

    -- init color
    self:attr_set("color", curses.color_pair("white", "blue"))
end

-- exit desktop
function desktop:exit()
    group.exit(self)
end

-- draw view
function desktop:draw()

    -- trace
    log:print("%s: draw ..", self)

    -- draw it
    local c = self:canvas()
    c:attr(self:attr("color")):move(0, 0):write(string.rep(' ', self:width() * self:height()))
end


-- return module
return desktop
