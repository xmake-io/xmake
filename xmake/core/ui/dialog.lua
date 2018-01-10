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

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local label  = require("ui/label")
local panel  = require("ui/panel")
local button = require("ui/button")
local window = require("ui/window")
local curses = require("ui/curses")

-- define module
local dialog = dialog or window()

-- init dialog
function dialog:init(name, bounds, title)

    -- init window
    window.init(self, name, bounds, title, true)

    -- init buttons
    local button_yes = button:new("dialog.button.yes", rect {0, self:panel():height() - 1, 7, 1}, "< Yes >")
    self:panel():insert(button_yes, {centerx = true})
end

-- return module
return dialog
