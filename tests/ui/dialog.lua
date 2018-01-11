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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        dialog.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.dialog")
import("core.ui.application")

-- the demo application
local demo = application()

-- init demo
function demo:init()

    -- init name 
    application.init(self, "demo")

    -- init background
    self:background_set("blue")

    -- init main dialog
    local dialog_main = dialog:new("dialog.main", rect {1, 1, self:width() - 1, self:height() - 1}, "main dialog")
    dialog_main:button_add("ok", "< OK >", "cm_ok")
    dialog_main:button_add("cancel", "< Cancel >", "cm_cancel")
    dialog_main:button_add("help", "< Help >", "cm_help")
    dialog_main:button_add("quit", "< Quit >", "cm_quit")
    self:insert(dialog_main)

    -- init hello dialog
    local dialog_hello = dialog:new("dialog.hello", rect {0, 0, self:width() / 2, self:height() / 4}):background_set(dialog_main:frame():background())
    dialog_hello:frame():background_set("green")
    dialog_hello:button_add("yes", "< Yes >", "cm_yes")
    dialog_hello:button_add("no", "< No >", "cm_no")
    self:insert(dialog_hello, {centerx = true, centery = true})
end

-- main entry
function main(...)
    demo:run(...)
end
