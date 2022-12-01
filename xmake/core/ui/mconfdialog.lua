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
-- @file        mconfdialog.lua
--

-- load modules
local table        = require("base/table")
local log          = require("ui/log")
local rect         = require("ui/rect")
local event        = require("ui/event")
local action       = require("ui/action")
local curses       = require("ui/curses")
local window       = require("ui/window")
local scrollbar    = require("ui/scrollbar")
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
Pressing <Y> includes, <N> excludes. Enter <Esc> or <Back> to go back, <?> for Help, </> for Search. Legend: [*] built-in  [ ] excluded
]])

    -- init buttons
    self:button_add("select", "< Select >", function (v, e) self:menuconf():on_event(event.command {"cm_enter"}) end)
    self:button_add("back", "< Back >", function (v, e)
        self:menuconf():on_event(event.command {"cm_back"})
        self:buttons():select(self:button("select"))
    end)
    self:button_add("exit", "< Exit >", function (v, e)
        self:show_exit([[Did you wish to save your new configuration?
(Pressing <Esc> to continue your configuration.)]])
    end)
    self:button_add("help", "< Help >", function (v, e) self:show_help() end)
    self:button_add("save", "< Save >", function (v, e) self:action_on(action.ac_on_save) end)
    self:buttons():select(self:button("select"))

    -- insert scrollbar
    self:box():panel():insert(self:scrollbar_menuconf())

    -- insert menu config
    self:box():panel():insert(self:menuconf())
    self:box():panel():action_add(action.ac_on_resized, function (v)
        local bounds = self:box():panel():bounds()
        self:menuconf():bounds_set(rect:new(0, 0, bounds:width(), bounds:height()))
    end)

    -- disable to select to box (disable Tab switch and only response to buttons)
    self:box():option_set("selectable", false)

    -- on resize for panel
    self:box():panel():action_add(action.ac_on_resized, function (v)
        self:menuconf():bounds_set(rect:new(0, 0, v:width() - 1, v:height()))
        self:scrollbar_menuconf():bounds_set(rect:new(v:width() - 1, 0, 1, v:height()))
        if self:menuconf():scrollable() then
            self:scrollbar_menuconf():show(true)
        else
            self:scrollbar_menuconf():show(false)
        end
    end)

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

    -- show scrollbar?
    self:menuconf():action_add(action.ac_on_load, function (v)
        if v:scrollable() then
            self:scrollbar_menuconf():show(true)
        else
            self:scrollbar_menuconf():show(false)
        end
    end)

    -- on scroll
    self:menuconf():action_add(action.ac_on_scrolled, function (v, progress)
        if self:scrollbar_menuconf():state("visible") then
            self:scrollbar_menuconf():progress_set(progress)
        end
    end)
end

-- load configs
function mconfdialog:load(configs)
    self._CONFIGS = configs
    return self:menuconf():load(configs)
end

-- get configs
function mconfdialog:configs()
    return self._CONFIGS
end

-- get menu config
function mconfdialog:menuconf()
    if not self._MENUCONF then
        local bounds = self:box():panel():bounds()
        self._MENUCONF = menuconf:new("mconfdialog.menuconf", rect:new(0, 0, bounds:width() - 1, bounds:height()))
        self._MENUCONF:state_set("focused", true) -- we can select and highlight selected item
    end
    return self._MENUCONF
end

-- get menu scrollbar
function mconfdialog:scrollbar_menuconf()
    if not self._SCROLLBAR_MENUCONF then
        local bounds = self:box():panel():bounds()
        self._SCROLLBAR_MENUCONF = scrollbar:new("mconfdialog.scrollbar", rect:new(bounds:width() - 1, 0, 1, bounds:height()))
        self._SCROLLBAR_MENUCONF:show(false)
    end
    return self._SCROLLBAR_MENUCONF
end

-- get help dialog
function mconfdialog:helpdialog()
    if not self._HELPDIALOG then
        local helpdialog = textdialog:new("mconfdialog.help", self:bounds(), "help")
        helpdialog:button_add("exit", "< Exit >", function (v) helpdialog:quit() end)
        helpdialog:option_set("scrollable", true)
        self._HELPDIALOG = helpdialog
    end
    return self._HELPDIALOG
end

-- get result dialog
function mconfdialog:resultdialog()
    if not self._RESULTDIALOG then
        local resultdialog = textdialog:new("mconfdialog.result", self:bounds(), "result")
        resultdialog:button_add("exit", "< Exit >", function (v) resultdialog:quit() end)
        resultdialog:option_set("scrollable", true)
        self._RESULTDIALOG = resultdialog
    end
    return self._RESULTDIALOG
end

-- get input dialog
function mconfdialog:inputdialog()
    if not self._INPUTDIALOG then
        local dialog_input = inputdialog:new("mconfdialog.input", rect{0, 0, math.min(80, self:width() - 8), math.min(8, self:height())}, "input dialog")
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
        local dialog_choice = choicedialog:new("mconfdialog.choice", rect{0, 0, math.min(80, self:width() - 8), math.min(20, self:height())}, "input dialog")
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
        local dialog_search = inputdialog:new("mconfdialog.input", rect{0, 0, math.min(80, self:width() - 8), math.min(8, self:height())}, "Search Configuration Parameter")
        dialog_search:background_set(self:frame():background())
        dialog_search:frame():background_set("cyan")
        dialog_search:textedit():option_set("multiline", false)
        dialog_search:text():text_set("Enter (sub)string or lua pattern string to search for configuration")
        dialog_search:button_add("ok", "< Ok >", function (v)
            local configs = self:search(self:configs(), dialog_search:textedit():text())
            local results = "Search('" .. dialog_search:textedit():text() .. "') results:"
            for _, config in ipairs(configs) do
                results = results .. "\n" .. config:prompt()
                if config.kind then
                    results = results .. "\nkind: " .. config.kind
                end
                if config.default then
                    results = results .. "\ndefault: " .. tostring(config.default)
                end
                if config.path then
                    results = results .. "\npath: " .. config.path
                end
                if config.sourceinfo then
                    results = results .. "\nposition: " .. (config.sourceinfo.file or "") .. ":" .. (config.sourceinfo.line or "-1")
                end
                results = results .. "\n"
            end
            self:show_result(results)
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

-- get exit dialog
function mconfdialog:exitdialog()
    if not self._EXITDIALOG then
        local exitdialog = textdialog:new("mconfdialog.exit", rect{0, 0, math.min(60, self:width() - 8), math.min(7, self:height())}, "")
        exitdialog:background_set(self:frame():background())
        exitdialog:frame():background_set("cyan")
        exitdialog:button_add("Yes", "< Yes >", function (v)
            self:action_on(action.ac_on_save)
        end)
        exitdialog:button_add("No", "< No >", function (v) self:quit() end)
        exitdialog:option_set("scrollable", false)
        exitdialog:button_select("Yes")
        self._EXITDIALOG = exitdialog
    end
    return self._EXITDIALOG
end

-- search configs via the given text
function mconfdialog:search(configs, text)
    local results = {}
    for _, config in ipairs(configs) do
        local prompt = config:prompt()
        if prompt and prompt:find(text) then
            table.insert(results, config)
        end
        if config.kind == "menu" then
            table.join2(results, self:search(config.configs, text))
        end
    end
    return results
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
        if config.kind == "choice" then
            if config.default and config.values[config.default] then
                text = text .. "\ndefault: " .. config.values[config.default]
            end
            text = text .. "\nvalues: "
            for _, value in ipairs(config.values) do
                text = text .. "\n    - " .. value
            end
        elseif config.default then
            text = text .. "\ndefault: " .. tostring(config.default)
        end
        if config.path then
            text = text .. "\npath: " .. config.path
        end
        if config.sourceinfo then
            text = text .. "\nposition: " .. (config.sourceinfo.file or "") .. ":" .. (config.sourceinfo.line or "-1")
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

-- show result dialog
function mconfdialog:show_result(text)
    local dialog_result = self:resultdialog()
    dialog_result:text():text_set(text)
    if not self:view("mconfdialog.result") then
        self:insert(dialog_result, {centerx = true, centery = true})
    else
        self:select(dialog_result)
    end
end

-- show exit dialog
function mconfdialog:show_exit(text)
    local dialog_exit = self:exitdialog()
    dialog_exit:text():text_set(text)
    if not self:view("mconfdialog.exit") then
        self:insert(dialog_exit, {centerx = true, centery = true})
    else
        self:select(dialog_exit)
    end
end

-- on event
function mconfdialog:on_event(e)

    -- select config
    if e.type == event.ev_keyboard then
        if e.key_name == "Down" or e.key_name == "Up" or e.key_name == " " or e.key_name == "Esc" or e.key_name:lower() == "y" or e.key_name:lower() == "n" then
            return self:menuconf():on_event(e)
        elseif e.key_name == "?" then
            self:show_help()
            return true
        elseif e.key_name == "/" then
            self:show_search()
            return true
        end
    end
    return boxdialog.on_event(self, e)
end

-- on resize
function mconfdialog:on_resize()
    if self._HELPDIALOG then
        self:helpdialog():bounds_set(self:bounds())
    end
    if self._RESULTDIALOG then
        self:resultdialog():bounds_set(self:bounds())
        self:center(self:resultdialog(), {centerx = true, centery = true})
    end
    if self._INPUTDIALOG then
        self:inputdialog():bounds_set(rect{0, 0, math.min(80, self:width() - 8), math.min(8, self:height())})
        self:center(self:inputdialog(), {centerx = true, centery = true})
    end
    if self._CHOICEDIALOG then
        self:choicedialog():bounds_set(rect{0, 0, math.min(80, self:width() - 8), math.min(20, self:height())})
        self:center(self:choicedialog(), {centerx = true, centery = true})
    end
    if self._SEARCHDIALOG then
        self:searchdialog():bounds_set(rect{0, 0, math.min(80, self:width() - 8), math.min(8, self:height())})
        self:center(self:searchdialog(), {centerx = true, centery = true})
    end
    boxdialog.on_resize(self)
end

-- return module
return mconfdialog
