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
-- @file        label.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local curses    = require("ui/curses")

-- define module
local label = label or view()

-- init label
function label:init(name, bounds, text)

    -- init view
    view.init(self, name, bounds)

    -- init text
    self._TEXT = text or ""

    -- init color
    self:attr_set("color", curses.color_pair("white", "blue"))
end

-- exit label
function label:exit()
    view.exit(self)
end

-- draw view
function label:draw()

    -- trace
    log:print("%s: draw ..", self)

    -- draw it
    local c = self:canvas()
    local s = string.sub(self:text(), 1, self:width()) .. string.rep(' ', self:width() - #self:text())
    c:attr(self:attr("color")):move(0, 0):write(s, self:attr("color"))
end

-- get text
function label:text()
    return self._TEXT
end

-- set text
function label:text_set(text)
    self._TEXT = text or ""
    self:invalidate()
end

-- return module
return label
