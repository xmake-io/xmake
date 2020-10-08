--!A cross-platform terminal ui library based on Lua
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
-- Copyright (C) 2020, TBOOX Open Source Group.
--
-- @author      Lael N. Santos
-- @file        events.lua
--

-- imports
import("core.ui.rect")
import("core.ui.label")
import("core.ui.event")
import("core.ui.window")
import("core.ui.application")

-- the demo application
local demo = application()

-- init demo
function demo:init()

    -- init name
    application.init(self, "demo")

    -- init background
    self:background_set("black")

    -- init body window
    self:insert(self:body_window())

    -- init teste
    self:body_window():panel():insert(self:teste())
end

-- get body window
function demo:body_window()
    if not self._BODY_WINDOW then
        self._BODY_WINDOW = window:new("window.body", rect {1, 1, self:width() - 1, self:height() - 1}, "main window")
    end
    return self._BODY_WINDOW
end

-- get teste label
function demo:teste()
    if not self._TESTE then
        self._TESTE = label:new('demo.label', rect {0, 0, 40, 5}, 'this is a test')
    end
    return self._TESTE
end

-- on resize
function demo:on_resize()
    self:body_window():bounds_set(rect {1, 1, self:width() - 1, self:height() - 1})
    application.on_resize(self)
end

-- on event
function demo:on_event(e)
    if e.type < event.ev_max then
        self:teste():text_set('type: ' ..
            tostring(e.type) ..
            '; name: ' ..
            tostring(e.key_name or e.btn_name) ..
            '; code: ' ..
            tostring(e.key_code or e.x) ..
            '; meta: ' ..
            tostring(e.key_code or e.y))
    end
    application.on_event(self, e)
end

-- main entry
function main(...)
    demo:run(...)
end
