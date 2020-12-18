--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
local action    = require("ui/action")
local curses    = require("ui/curses")
local button    = require("ui/button")
local object    = require("ui/object")

-- define module
local menuconf = menuconf or panel()

-- init menuconf
function menuconf:init(name, bounds)

    -- init panel
    panel.init(self, name, bounds)

    -- init configs
    self._CONFIGS = {}

    -- init items
    self._ITEMS = {}

    -- init start index
    self._STARTINDEX = 1
end

-- load configs
function menuconf:load(configs)

    -- clear the views first
    self:clear()

    -- reset start index
    self._STARTINDEX = 1

    -- detach the previous config and view
    local configs_prev = self._CONFIGS._PREV
    if configs_prev then
        for _, config in ipairs(configs_prev) do
            config._view = nil
        end
    end

    -- save configs
    self._CONFIGS = configs

    -- load items
    local items = {}
    for idx, config in ipairs(configs) do
        table.insert(items, self:_load_item(config, idx))
    end
    self._ITEMS = items

    -- insert top-n items
    local startindex = self._STARTINDEX
    for idx = startindex, startindex + self:height() - 1 do
        local item = items[idx]
        if item then
            self:insert(item)
        else
            break
        end
    end

    -- select the first item
    self:select(self:first())

    -- on loaded
    self:action_on(action.ac_on_load)

    -- invalidate
    self:invalidate()
end

-- is scrollable?
function menuconf:scrollable()
    return #self:_items() > self:height()
end

-- scroll
function menuconf:scroll(count)
    if self:scrollable() then
        local items = self:_items()
        local totalcount = #items
        local startindex = self._STARTINDEX + count
        if startindex > totalcount then
            return
        elseif startindex < 1 then
            startindex = 1
        end
        self._STARTINDEX = startindex
        self:clear()
        for idx = startindex, startindex + self:height() - 1 do
            local item = items[idx]
            if item then
                item:bounds():move2(0, idx - startindex)
                self:insert(item)
            else
                break
            end
        end
        if count > 0 then
            self:select(self:first())
        else
            self:select(self:last())
        end
        self:invalidate()
    end
end

-- on resize
function menuconf:on_resize()
    local items = self:_items()
    local totalcount = #items
    local startindex = self._STARTINDEX
    for idx = 1, totalcount do
        local item = items[idx]
        if item then
            if idx >= startindex and idx < startindex + self:height() then
                if not self:view(item:name()) then
                    item:bounds():move2(0, idx - startindex)
                    self:insert(item)
                end
            else
                if self:view(item:name()) then
                    self:remove(item)
                end
            end
        end
    end
    panel.on_resize(self)
end

-- on event
function menuconf:on_event(e)
    local back = false
    if e.type == event.ev_keyboard then
        if e.key_name == "Down" then
            if self:current() == self:last() then
                self:scroll(self:height())
            else
                self:select_next()
            end
            self:_notify_scrolled()
            return true
        elseif e.key_name == "Up" then
            if self:current() == self:first() then
                self:scroll(-self:height())
            else
                self:select_prev()
            end
            self:_notify_scrolled()
            return true
        elseif e.key_name == "PageDown" or e.key_name == "PageUp" then
            local direction = e.key_name == "PageDown" and 1 or -1
            self:scroll(self:height() * direction)
            self:_notify_scrolled()
            return true
        elseif e.key_name == "Enter" or e.key_name == " " then
            self:_do_select()
            return true
        elseif e.key_name:lower() == "y" then
            self:_do_include(true)
            return true
        elseif e.key_name:lower() == "n" then
            self:_do_include(false)
            return true
        elseif e.key_name == "Esc" then
            back = true
        end
    elseif e.type == event.ev_command then
        if e.command == "cm_enter" then
            self:_do_select()
            return true
        elseif e.command == "cm_back" then
            back = true
        end
    end

    -- back?
    if back then
        -- load the previous menu configs
        local configs_prev = self._CONFIGS._PREV
        if configs_prev then
            self._CONFIGS._PREV = configs_prev._PREV
            self:load(configs_prev)
            return true
        end
    end
end

-- load a config item
function menuconf:_load_item(config, index)

    -- init a config item view
    local item = button:new("menuconf.config." .. index,
                    rect:new(0, index - 1, self:width(), 1),
                    tostring(config),
                    function (v, e)
                        self:_do_select()
                    end)

    -- attach this index and config
    item:extra_set("index", index)
    item:extra_set("config", config)

    -- attach this view
    config._view = item
    return item
end

-- notify scrolled
function menuconf:_notify_scrolled()
    local totalcount = #self:_items()
    local startindex = self:current():extra("index")
    self:action_on(action.ac_on_scrolled, startindex / totalcount)
end

-- get all items
function menuconf:_items()
    return self._ITEMS
end

-- do select the current config
function menuconf:_do_select()

    -- get the current item
    local item = self:current()

    -- get the current config
    local config = item:extra("config")

    -- clear new state
    config.new = false

    -- do action: on selected
    if self:action_on(action.ac_on_selected, config) then
        return
    end

    -- select the boolean config
    if config.kind == "boolean" then
        config.value = not config.value
    -- show sub-menu configs
    elseif config.kind == "menu" and config.configs and #config.configs > 0 then
        local configs_prev = self._CONFIGS
        self:load(config.configs)
        self._CONFIGS._PREV = configs_prev
    end
end

-- do include
function menuconf:_do_include(enabled)

    -- get the current item
    local item = self:current()

    -- get the current config
    local config = item:extra("config")

    -- clear new state
    config.new = false

    -- select the boolean config
    if config.kind == "boolean" then
        config.value = enabled
    end
end

-- init config object
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
-- choice config (value is index)
--  - {name = "...", kind = "choice", value = 1, default = 1, description = "choice config item", values = {2, 2, 3, 4, 5}}
--
-- menu config
--  - {name = "...", kind = "menu", description = "menu config item", configs = {...}}
--
local config = config or object{new = true,
                                __index = function (tbl, key)
                                    if key == "value" then
                                        local val = rawget(tbl, "_value")
                                        if val == nil then
                                            val = rawget(tbl, "default")
                                        end
                                        return val
                                    end
                                    return rawget(tbl, key)
                                end,
                                __newindex = function (tbl, key, val)
                                    if key == "value" then
                                        key = "_value"
                                    end
                                    rawset(tbl, key, val)
                                    if key == "_value" then
                                        local v = rawget(tbl, "_view") -- update the config item text in view
                                        if v then
                                            v:text_set(tostring(tbl))
                                        end
                                    end
                                end}

-- the prompt info
function config:prompt()

    -- get text (first line in description)
    local text = self.description or ""
    if type(text) == "table" then
        text = text[1] or ""
    end
    return text
end

-- to string
function config:__tostring()

    -- get text (first line in description)
    local text = self:prompt()

    -- get value
    local value = self.value

    -- update text
    if self.kind == "boolean" or (not self.kind and type(value) == "boolean") then -- boolean config?
        text = (value and "[*] " or "[ ] ") .. text
    elseif self.kind == "number" or (not self.kind and type(value) == "number") then -- number config?
        text = "    " .. text .. " (" .. tostring(value or 0) .. ")"
    elseif self.kind == "string" or (not self.kind and type(value) == "string") then -- string config?
        text = "    " .. text .. " (" .. tostring(value or "") .. ")"
    elseif self.kind == "choice" then -- choice config?
        if self.values and #self.values > 0 then
            text = "    " .. text .. " (" .. tostring(self.values[value or 1]) .. ")" .. "  --->"
        else
            text = "    " .. text .. " ()  ----"
        end
    elseif self.kind == "menu" then -- menu config?
        text = "    " .. text .. (self.configs and #self.configs > 0 and "  --->" or "  ----")
    end

    -- new config?
    if self.new and self.kind ~= "choice" and self.kind ~= "menu" then
        text = text .. " (NEW)"
    end

    -- ok
    return text
end

-- save config objects
menuconf.config  = menuconf.config or config
menuconf.menu    = menuconf.menu or config { kind = "menu", configs = {} }
menuconf.number  = menuconf.number or config { kind = "number", default = 0 }
menuconf.string  = menuconf.string or config { kind = "string", default = "" }
menuconf.choice  = menuconf.choice or config { kind = "choice", default = 1, values = {} }
menuconf.boolean = menuconf.boolean or config { kind = "boolean", default = false }

-- return module
return menuconf
