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
-- @file        inputdialog.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.inputdialog")
import("core.ui.application")

-- the demo application
local demo = application()

-- init demo
function demo:init()

    -- init name
    application.init(self, "demo")

    -- init background
    self:background_set("blue")

    -- init input dialog
    self:insert(self:dialog_input(), {centerx = true, centery = true})
end

-- input dialog
function demo:dialog_input()
    local dialog_input = self._DIALOG_INPUT
    if not dialog_input then
        dialog_input = inputdialog:new("dialog.input", rect{0, 0, math.floor(self:width() / 2), math.floor(self:height() / 3)})
        dialog_input:text():text_set("please input text:")
        dialog_input:button_add("no", "< No >", function (v) dialog_input:quit() end)
        dialog_input:button_add("yes", "< Yes >", function (v) dialog_input:quit() end)
        self._DIALOG_INPUT = dialog_input
    end
    return dialog_input
end

-- on resize
function demo:on_resize()
    self:dialog_input():bounds_set(rect{0, 0, math.floor(self:width() / 2), math.floor(self:height() / 3)})
    self:center(self:dialog_input(), {centerx = true, centery = true})
    application.on_resize(self)
end

-- main entry
function main(...)
    demo:run(...)
end
