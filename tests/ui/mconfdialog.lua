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
-- @file        mconfdialog.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.action")
import("core.ui.menuconf")
import("core.ui.mconfdialog")
import("core.ui.application")

-- the demo application
local demo = application()

-- init demo
function demo:init()

    -- init name
    application.init(self, "demo")

    -- init background
    self:background_set("blue")

    -- init configs
    local configs_sub2 = {}
    table.insert(configs_sub2, menuconf.boolean {description = "boolean config sub-item2"})
    table.insert(configs_sub2, menuconf.number {value = 10, default = 10, description = "number config sub-item2"})
    table.insert(configs_sub2, menuconf.string {value = "armv7", description = "string config sub-item2"})
    table.insert(configs_sub2, menuconf.menu {description = "menu config sub-item2"})

    local configs_sub = {}
    table.insert(configs_sub, menuconf.boolean {description = "boolean config sub-item"})
    table.insert(configs_sub, menuconf.number {value = 90, default = 10, description = "number config sub-item"})
    table.insert(configs_sub, menuconf.string {value = "arm64", description = "string config sub-item"})
    table.insert(configs_sub, menuconf.menu {description = "menu config sub-item", configs = configs_sub2})
    table.insert(configs_sub, menuconf.choice {value = 2, values = {2, 5, 16, 87}, description = "choice config sub-item"})

    local configs = {}
    table.insert(configs, menuconf.boolean {description = "boolean config item"})
    table.insert(configs, menuconf.boolean {default = true, new = false, description = {"boolean config item2",
                                                                                        "  - more description info",
                                                                                        "  - more description info",
                                                                                        "  - more description info"}})
    table.insert(configs, menuconf.number {value = 6, default = 10, description = "number config item"})
    table.insert(configs, menuconf.string {value = "x86_64", description = "string config item"})
    table.insert(configs, menuconf.menu {description = "menu config item", configs = configs_sub})
    table.insert(configs, menuconf.choice {value = 3, values = {1, 5, 6, 7}, description = "choice config item"})

    -- init menu config dialog
    self:dialog_mconf():load(configs)
    self:insert(self:dialog_mconf())
end

-- get mconfdialog
function demo:dialog_mconf()
    local dialog_mconf = self._DIALOG_MCONF
    if not dialog_mconf then
        dialog_mconf = mconfdialog:new("mconfdialog.main", rect{1, 1, self:width() - 1, self:height() - 1}, "menu config")
        dialog_mconf:action_set(action.ac_on_exit, function (v) self:quit() end)
        dialog_mconf:action_set(action.ac_on_save, function (v)
            -- TODO save configs
            dialog_mconf:quit()
        end)
        self._DIALOG_MCONF = dialog_mconf
    end
    return dialog_mconf
end

-- on resize
function demo:on_resize()
    self:dialog_mconf():bounds_set(rect{1, 1, self:width() - 1, self:height() - 1})
    application.on_resize(self)
end

-- main entry
function main(...)
    demo:run(...)
end
