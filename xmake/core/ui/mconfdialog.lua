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

-- load modules
local log        = require("ui/log")
local rect       = require("ui/rect")
local event      = require("ui/event")
local action     = require("ui/action")
local curses     = require("ui/curses")
local window     = require("ui/window")
local menuconf   = require("ui/menuconf")
local boxdialog  = require("ui/boxdialog")

-- define module
local mconfdialog = mconfdialog or boxdialog()

-- init dialog
function mconfdialog:init(name, bounds, title)

    -- init window
    boxdialog.init(self, name, bounds, title)

    -- init text
    self:text():text_set([[Arrow keys navigate the menu. <Enter> selects submenus ---> (or empty submenus ----). 
Pressing <Y> includes, <N> excludes. Enter <Esc> to go back or exit, <?> for Help, </> for Search. Legend: [*] built-in  [ ] excluded
]])

    -- init buttons
    self:button_add("select", "< Select >", function (v, e) end)
    self:button_add("exit", "< Exit >", function (v, e) self:quit() end)
    self:button_add("help", "< Help >", function (v, e) end)
    self:button_add("save", "< Save >", function (v, e) self:action_on(action.ac_on_save) end)
    self:button_add("load", "< Load >", function (v, e) self:action_on(action.ac_on_load) end)
    self:buttons():select(self:button("select"))

    -- insert menu config
    self:box():panel():insert(self:menuconf())
end

-- get menu config
function mconfdialog:menuconf()
    if not self._MENUCONF then
        self._MENUCONF = menuconf:new("mconfdialog.menuconf", self:box():bounds())
    end
    return self._MENUCONF
end

-- on event
function mconfdialog:event_on(e)
    -- TODO
    return boxdialog.event_on(self, e) 
end

-- return module
return mconfdialog
