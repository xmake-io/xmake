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
-- @file        textdialog.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local label  = require("ui/label")
local dialog = require("ui/dialog")
local curses = require("ui/curses")

-- define module
local textdialog = textdialog or dialog()

-- init dialog
function textdialog:init(name, bounds, title)

    -- init window
    dialog.init(self, name, bounds, title)

    -- insert text
    self:panel():insert(self:text())
end

-- get text
function textdialog:text()
    if not self._TEXT then
        self._TEXT = label:new("textdialog.text", rect:new(0, 0, self:panel():width(), self:panel():height() - 1))
    end
    return self._TEXT
end

-- return module
return textdialog
