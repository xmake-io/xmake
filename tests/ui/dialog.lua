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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
import("core.ui.boxdialog")
import("core.ui.textdialog")
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

    -- init help dialog
    local dialog_help = textdialog:new("dialog.help", rect {1, 1, self:width() - 1, self:height() - 1}, "README")
    dialog_help:text():text_set(io.readfile(path.join(os.scriptdir(), "dialog.lua")))
    dialog_help:button_add("exit", "< Exit >", function (v) self:remove(dialog_help) end)

    -- init main dialog
    local dialog_main = boxdialog:new("dialog.main", rect {1, 1, self:width() - 1, self:height() - 1}, "main dialog")
    dialog_main:text():text_set("The project focuses on making development and building easier and provides many features (e.g. package, install, plugin, macro, action, option, task ...), so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.")
    dialog_main:button_add("tips", "< Tips >", function (v) self:view("dialog.tips"):show(true, {focused = true}) end)
    dialog_main:button_add("input", "< Input >", function (v) self:view("dialog.input"):show(true, {focused = true}) end)
    dialog_main:button_add("help", "< Help >", function (v) self:insert(dialog_help) end)
    dialog_main:button_add("quit", "< Quit >", "cm_quit")
    self:insert(dialog_main)

    -- init input dialog
    local dialog_input = inputdialog:new("dialog.input", rect {0, 0, 50, 8}):background_set(dialog_main:frame():background())
    dialog_input:frame():background_set("cyan")
    dialog_input:text():text_set("please input text:"):textattr_set("red")
    dialog_input:button_add("no", "< No >", function (v) dialog_input:show(false) end)
    dialog_input:button_add("yes", "< Yes >", function (v) 
                                                  dialog_main:text():text_set(dialog_input:textedit():text())
                                                  dialog_input:show(false) 
                                              end)
    self:insert(dialog_input, {centerx = true, centery = true})
    dialog_input:show(false)

    -- init tips dialog
    local dialog_tips = textdialog:new("dialog.tips", rect {0, 0, 50, 8}):background_set(dialog_main:frame():background())
    dialog_tips:frame():background_set("cyan")
    dialog_tips:text():text_set("hello xmake! (http://xmake.io)\nA cross-platform build utility based on Lua"):textattr_set("red")
    dialog_tips:button_add("yes", "< Yes >", function (v) dialog_tips:show(false) end)
    dialog_tips:button_add("no", "< No >", function (v) dialog_tips:show(false) end)
    self:insert(dialog_tips, {centerx = true, centery = true})
end

-- main entry
function main(...)
    demo:run(...)
end
