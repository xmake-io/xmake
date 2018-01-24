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
end

-- insert a config item
--
-- kind
--  - {kind = "number/boolean/string/choice/menu"}
--
-- description
--  - {description = "config item description"}
--  - {description = {"config item description", "line2", "line3", "more description ..."}}
--
-- boolean config
--  - {name = "...", kind = "boolean", value = true, default = true, description = "boolean config item", new = true/false}
--
-- number config
--  - {name = "...", kind = "number", value = 10, default = 0, description = "number config item", new = true/false}
--
-- string config
--  - {name = "...", kind = "string", value = "xmake", default = "", description = "string config item", new = true/false}
--
-- choice config
--  - {name = "...", kind = "choice", value = "...", default = "...", description = "choice config item", values = {1, 2, 3, 4, 5}}
--
-- menu config
--  - {name = "...", kind = "menu", description = "menu config item", configs = {...}}
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

    -- get value
    local value = config.value or config.default

    -- update text
    if config.kind == "boolean" or (not config.kind and type(value) == "boolean") then -- boolean config?
        text = (value and "[*] " or "[ ] ") .. text
    elseif config.kind == "number" or (not config.kind and type(value) == "number") then -- number config?
        text = "(" .. tostring(value or 0) .. ") " .. text
    elseif config.kind == "string" or (not config.kind and type(value) == "string") then -- string config?
        text = "(" .. tostring(value or "") .. ") " .. text
    elseif config.kind == "choice" then -- choice config?
        text = "    " .. text .. " (" .. tostring(value or "") .. ")" .. "  --->"
    elseif config.kind == "menu" then -- menu config?
        text = "    " .. text .. "  --->"
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
