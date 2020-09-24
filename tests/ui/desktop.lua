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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        desktop.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.button")
import("core.ui.application")

-- the demo application
local demo = application()

-- init demo
function demo:init()

    -- init name
    application.init(self, "demo")

    -- show desktop, menubar and statusbar
    self:insert(self:desktop())
    self:insert(self:menubar())
    self:insert(self:statusbar())

    -- init title
    self:menubar():title():text_set("Menu Bar (Hello)")

    -- add title label
    self:desktop():insert(label:new("title", rect {0, 0, 12, 1}, "hello ltui!"):textattr_set("white"), {centerx = true})

    -- add yes button
    self:desktop():insert(button:new("yes", rect {0, 1, 7, 2}, "< Yes >"):textattr_set("white"), {centerx = true})

    -- add no button
    self:desktop():insert(button:new("no", rect {0, 2, 6, 3}, "< No >"):textattr_set("white"), {centerx = true})
end

-- on event
function demo:on_event(e)
    if application.on_event(self, e) then
        return true
    end
    if e.type == event.ev_keyboard then
        self:statusbar():info():text_set(e.key_name)
        if e.key_name == "s" then
            self:statusbar():show(not self:statusbar():state("visible"))
        elseif e.key_name == "m" then
            self:menubar():show(not self:menubar():state("visible"))
        elseif e.key_name == "d" then
            self:desktop():show(not self:desktop():state("visible"))
        end
    end
end

-- on resize
function demo:on_resize()
    for v in self:desktop():views() do
        self:center(v, {centerx = true})
    end
    application.on_resize(self)
end

-- main entry
function main(...)
    demo:run(...)
end
