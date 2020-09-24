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

    -- init main dialog
    self:insert(self:dialog_main())

    -- init input dialog
    self:insert(self:dialog_input(), {centerx = true, centery = true})

    -- init tips dialog
    self:insert(self:dialog_tips(), {centerx = true, centery = true})
end

-- main dialog
function demo:dialog_main()
    local dialog_main = self._DIALOG_MAIN
    if not dialog_main then
        dialog_main = boxdialog:new("dialog.main", rect {1, 1, self:width() - 1, self:height() - 1}, "main dialog")
        dialog_main:text():text_set("The project focuses on making development and building easier and provides many features (.e.g package, install, plugin, macro, action, option, task ...), so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.")
        dialog_main:button_add("tips", "< Tips >", function (v) self:view("dialog.tips"):show(true, {focused = true}) end)
        dialog_main:button_add("input", "< Input >", function (v) self:view("dialog.input"):show(true, {focused = true}) end)
        dialog_main:button_add("help", "< Help >", function (v) self:insert(self:dialog_help()) end)
        dialog_main:button_add("quit", "< Quit >", "cm_quit")
        self._DIALOG_MAIN = dialog_main
    end
    return dialog_main
end

-- help dialog
function demo:dialog_help()
    local dialog_help = self._DIALOG_HELP
    if not dialog_help then
        dialog_help = textdialog:new("dialog.help", rect {1, 1, self:width() - 1, self:height() - 1}, "README")
        local helptext = nil
        local file = io.open("./LICENSE.md", 'r')
        if file then
            helptext = file:read("*a")
            file:close()
        end
        if helptext then
            dialog_help:text():text_set(helptext)
        end
        dialog_help:button_add("exit", "< Exit >", function (v) self:remove(dialog_help) end)
        self._DIALOG_HELP = dialog_help
    end
    return dialog_help
end

-- input dialog
function demo:dialog_input()
    local dialog_input = self._DIALOG_INPUT
    if not dialog_input then
        dialog_input = inputdialog:new("dialog.input", rect {0, 0, 50, 8}):background_set(self:dialog_main():frame():background())
        dialog_input:frame():background_set("cyan")
        dialog_input:text():text_set("please input text:"):textattr_set("red")
        dialog_input:button_add("no", "< No >", function (v) dialog_input:show(false) end)
        dialog_input:button_add("yes", "< Yes >", function (v)
                                                      self:dialog_main():text():text_set(dialog_input:textedit():text())
                                                      dialog_input:show(false)
                                                  end)
        dialog_input:show(false)
        self._DIALOG_INPUT = dialog_input
    end
    return dialog_input
end

-- tips dialog
function demo:dialog_tips()
    local dialog_tips = self._DIALOG_TIPS
    if not dialog_tips then
        dialog_tips = textdialog:new("dialog.tips", rect {0, 0, 50, 8}):background_set(self:dialog_main():frame():background())
        dialog_tips:frame():background_set("cyan")
        dialog_tips:text():text_set("hello ltui! (https://tboox.org)\nA cross-platform terminal ui library based on Lua"):textattr_set("red")
        dialog_tips:button_add("yes", "< Yes >", function (v) dialog_tips:show(false) end)
        dialog_tips:button_add("no", "< No >", function (v) dialog_tips:show(false) end)
        self._DIALOG_TIPS = dialog_tips
    end
    return dialog_tips
end

-- on resize
function demo:on_resize()
    self:dialog_main():bounds_set(rect {1, 1, self:width() - 1, self:height() - 1})
    self:dialog_help():bounds_set(rect {1, 1, self:width() - 1, self:height() - 1})
    self:center(self:dialog_input(), {centerx = true, centery = true})
    self:center(self:dialog_tips(), {centerx = true, centery = true})
    application.on_resize(self)
end

-- main entry
function main(...)
    demo:run(...)
end
