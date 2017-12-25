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
-- @file        hello.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.application")

-- the hello application
local hello = application()

-- init hello
function hello:init()

    -- init name 
    application.init(self, "hello")

    -- init title
    self:menubar():title_set("Menu Bar (Hello)")

    -- add title label
    self:desktop():insert(label:new("title", rect {0, 0, 12, 1}, "hello xmake!"), {centerx = true})
end

-- on event
function hello:event_on(e)
    view.event_on(self, e)
    if e.type == event.ev_keyboard then
        self:statusbar():info_set(e.key_name)
        if e.key_name == "s" then
            self:statusbar():show(not self:statusbar():state("visible"))
        elseif e.key_name == "m" then
            self:menubar():show(not self:menubar():state("visible"))
        elseif e.key_name == "d" then
            self:desktop():show(not self:desktop():state("visible"))
        elseif e.key_name == "q" then
            self:quit()
        end
    end
end

-- main entry
function main(...)
    hello:run(...)
end
