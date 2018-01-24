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
-- @file        mconfdialog.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.view")
import("core.ui.label")
import("core.ui.event")
import("core.ui.action")
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

    -- init menu config dialog
    local mconfdialog = mconfdialog:new("mconfdialog.main", rect {1, 1, self:width() - 1, self:height() - 1}, "menu config")
    mconfdialog:action_set(action.ac_on_exit, function (v) self:quit() end)
    mconfdialog:action_set(action.ac_on_load, function (v) 
        local menuconf = v:menuconf()
        menuconf:insert({default = false, description = "boolean config item"})
        menuconf:insert({default = true, new = true, description = {"boolean config item2", "more"}})
        menuconf:insert({kind = "number", value = 6, default = 10, description = "number config item"})
        menuconf:insert({value = "x86_64", description = "string config item"})
        menuconf:insert({kind = "menu", description = "menu config item"})
        menuconf:insert({kind = "choice", value = 3, values = {1, 5, 6, 7}, description = "choice config item"})
    end)
    mconfdialog:action_set(action.ac_on_save, function (v) log:print("save") end)
    self:insert(mconfdialog)
end

-- main entry
function main(...)
    demo:run(...)
end
