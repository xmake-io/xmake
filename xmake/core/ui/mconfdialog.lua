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
local log          = require("ui/log")
local rect         = require("ui/rect")
local event        = require("ui/event")
local action       = require("ui/action")
local curses       = require("ui/curses")
local window       = require("ui/window")
local menuconf     = require("ui/menuconf")
local boxdialog    = require("ui/boxdialog")
local textdialog   = require("ui/textdialog")
local inputdialog  = require("ui/inputdialog")
local choicedialog = require("ui/choicedialog")

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
    self:button_add("select", "< Select >", function (v, e) self:menuconf():event_on(event.command {"cm_enter"}) end)
    self:button_add("exit", "< Exit >", function (v, e) self:quit() end)
    self:button_add("help", "< Help >", function (v, e) self:show_help() end) 
    self:button_add("save", "< Save >", function (v, e) self:action_on(action.ac_on_save) end)
    self:buttons():select(self:button("select"))

    -- insert menu config
    self:box():panel():insert(self:menuconf())

    -- disable to select to box (disable Tab switch and only response to buttons)
    self:box():option_set("selectable", false)

    -- on selected
    self:menuconf():action_set(action.ac_on_selected, function (v, config)

        -- show input dialog
        if config.kind == "string" or config.kind == "number" then
            local dialog_input = self:inputdialog()
            dialog_input:extra_set("config", config)
            dialog_input:title():text_set(config:prompt())
            dialog_input:textedit():text_set(tostring(config.value))
            dialog_input:panel():select(dialog_input:textedit())
            if config.kind == "string" then
                dialog_input:text():text_set("Please enter a string value. Use the <TAB> key to move from the input fields to buttons below it.")
            else
                dialog_input:text():text_set("Please enter a decimal value. Fractions will not be accepted.  Use the <TAB> key to move from the input field to the buttons below it.")
            end
            self:insert(dialog_input, {centerx = true, centery = true})
            return true

        -- show choice dialog
        elseif config.kind == "choice" and config.values and #config.values > 0 then
            local dialog_choice = self:choicedialog()
            dialog_choice:title():text_set(config:prompt())
            dialog_choice:choicebox():load(config.values, config.value)
            dialog_choice:choicebox():action_set(action.ac_on_selected, function (v, index, value)
                config.value = index
            end)
            self:insert(dialog_choice, {centerx = true, centery = true})
            return true
        end
    end)
end

-- load configs
function mconfdialog:load(configs)
    return self:menuconf():load(configs)
end

-- get menu config
function mconfdialog:menuconf()
    if not self._MENUCONF then
        local bounds = self:box():panel():bounds()
        self._MENUCONF = menuconf:new("mconfdialog.menuconf", rect:new(0, 0, bounds:width(), bounds:height()))
        self._MENUCONF:state_set("focused", true) -- we can select and highlight selected item
    end
    return self._MENUCONF
end

-- get help dialog
function mconfdialog:helpdialog()
    if not self._HELPDIALOG then
        local helpdialog = textdialog:new("mconfdialog.help", self:bounds(), "help")
        helpdialog:button_add("exit", "< Exit >", function (v) helpdialog:quit() end)
        self._HELPDIALOG = helpdialog
    end
    return self._HELPDIALOG
end

-- get input dialog
function mconfdialog:inputdialog()
    if not self._INPUTDIALOG then
        local dialog_input = inputdialog:new("mconfdialog.input", rect {0, 0, math.min(80, self:width() - 8), math.min(8, self:height())}, "input dialog")
        dialog_input:background_set(self:frame():background())
        dialog_input:frame():background_set("cyan")
        dialog_input:textedit():option_set("multiline", false)
        dialog_input:button_add("ok", "< Ok >", function (v) 
            local config = dialog_input:extra("config")
            if config.kind == "string" then
                config.value = dialog_input:textedit():text()
            elseif config.kind == "number" then
                local value = tonumber(dialog_input:textedit():text())
                if value ~= nil then
                    config.value = value
                end
            end
            dialog_input:quit() 
        end)
        dialog_input:button_add("cancel", "< Cancel >", function (v) 
            dialog_input:quit()
        end)
        dialog_input:button_select("ok")
        self._INPUTDIALOG = dialog_input
    end
    return self._INPUTDIALOG
end

-- get choice dialog
function mconfdialog:choicedialog()
    if not self._CHOICEDIALOG then
        local dialog_choice = choicedialog:new("mconfdialog.choice", rect {0, 0, math.min(80, self:width() - 8), math.min(20, self:height())}, "input dialog")
        dialog_choice:background_set(self:frame():background())
        dialog_choice:frame():background_set("cyan")
        dialog_choice:box():frame():background_set("cyan")
        self._CHOICEDIALOG = dialog_choice
    end
    return self._CHOICEDIALOG
end

-- get search dialog
function mconfdialog:searchdialog()
    if not self._SEARCHDIALOG then
        local dialog_search = inputdialog:new("mconfdialog.input", rect {0, 0, math.min(80, self:width() - 8), math.min(8, self:height())}, "Search Configuration Parameter")
        dialog_search:background_set(self:frame():background())
        dialog_search:frame():background_set("cyan")
        dialog_search:textedit():option_set("multiline", false)
        dialog_search:text():text_set("Enter (sub)string or lua pattern string to search for configuration")
        dialog_search:button_add("ok", "< Ok >", function (v) 
            -- TODO
            dialog_search:quit() 
        end)
        dialog_search:button_add("cancel", "< Cancel >", function (v) 
            dialog_search:quit()
        end)
        dialog_search:button_select("ok")
        self._SEARCHDIALOG = dialog_search
    end
    return self._SEARCHDIALOG
end

-- show help dialog
function mconfdialog:show_help()
    if self:parent() then

        -- get the current config item
        local item = self:menuconf():current()
        
        -- get the current config
        local config = item:extra("config")

        -- set help title
        self:helpdialog():title():text_set(config:prompt())

        -- set help text
        local text = config.description
        if type(text) == "table" then
            text = table.concat(text, '\n')
        end
        if config.kind then
            text = text .. "\ntype: " .. config.kind
        end
        if config.default then
            text = text .. "\ndefault: " .. tostring(config.default)
        end
        self:helpdialog():text():text_set(text)

        -- show help
        self:parent():insert(self:helpdialog())
    end
end

-- show search dialog
function mconfdialog:show_search()
    local dialog_search = self:searchdialog()
    dialog_search:panel():select(dialog_search:textedit())
    self:insert(dialog_search, {centerx = true, centery = true})
end

-- on event
function mconfdialog:event_on(e)

    -- select config
    if e.type == event.ev_keyboard then
        if e.key_name == "Down" or e.key_name == "Up" or e.key_name == " " or e.key_name == "Esc" or e.key_name:lower() == "y" or e.key_name:lower() == "n" then
            return self:menuconf():event_on(e)
        elseif e.key_name == "?" then
            self:show_help()
            return true
        elseif e.key_name == "/" then
            self:show_search()
            return true
        end
    end
    return boxdialog.event_on(self, e) 
end

-- return module
return mconfdialog
