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
-- @file        menuconf.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local rect      = require("ui/rect")
local panel     = require("ui/panel")
local event     = require("ui/event")
local curses    = require("ui/curses")
local button    = require("ui/button")

-- define module
local menuconf = menuconf or panel()

-- init menuconf
function menuconf:init(name, bounds)

    -- init panel
    panel.init(self, name, bounds)

    self:insert({default = false, description = "bool config item"})
    self:insert({default = true, new = true, description = {"bool config item2", "more"}})
end

-- insert a config item
--
-- description
--  - {description = "config item description"}
--  - {description = {"config item description", "line2", "line3", "more description ..."}}
--
-- bool config
--  - {default = true/false, description = "bool config item", new = true/false}
--
function menuconf:insert(config)

    -- init a config item view
    local item = button:new("menuconf.config." .. self:count(), rect:new(0, self:count(), self:width(), 1), self:_text(config))

    -- attach this config
    item:extra_set("config", config)

    -- insert this config item
    panel.insert(self, item)

    -- invalidate
    self:invalidate()
end

-- get text from the given config
function menuconf:_text(config)

    -- get text (first line in description)
    local text = config.description or ""
    if type(text) == "table" then
        text = text[1] or ""
    end

    -- update text
    if type(config.default) == "boolean" then
        text = (config.default and "[*] " or "[ ] ") .. text
    end

    -- new config?
    if config.new then
        text = text .. " (NEW)"
    end

    -- ok
    return text
end

-- return module
return menuconf
