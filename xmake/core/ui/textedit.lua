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
-- @file        textedit.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local label     = require("ui/label")
local event     = require("ui/event")
local border    = require("ui/border")
local curses    = require("ui/curses")
local textarea  = require("ui/textarea")
local action    = require("ui/action")
local bit       = require("base/bit")

-- define module
local textedit = textedit or textarea()

-- init textedit
function textedit:init(name, bounds, text)

    -- init label
    textarea.init(self, name, bounds, text)

    -- show cursor
    self:cursor_show(true)

    -- mark as selectable
    self:option_set("selectable", true)

    -- mark as mouseable
    self:option_set("mouseable", true)
    self:action_set(action.ac_on_clicked, function () return true end)

    -- enable multiple line
    self:option_set("multiline", true)
end

-- draw textedit
function textedit:on_draw(transparent)

    -- draw label
    textarea.on_draw(self, transparent)

    -- move cursor
    if not self:text() or #self:text() == 0 then
        self:cursor_move(0, 0)
    else
        self:cursor_move(self:canvas():pos())
    end
end

-- set text
function textedit:text_set(text)
    textarea.text_set(self, text)
    self:scroll_to_end()
    return self
end

-- on event
function textedit:on_event(e)

    -- update text
    if e.type == event.ev_keyboard then
        if e.key_name == "Enter" and self:option("multiline") then
            self:text_set(self:text() .. '\n')
            return true
        elseif e.key_name == "Backspace" then
            local text = self:text()
            if #text > 0 then
                local size = 1
                -- while continuation byte
                while bit.band(text:byte(#text - size + 1), 0xc0) == 0x80 do
                    size = size + 1
                end
                self:text_set(text:sub(1, #text - size))
            end
            return true
        elseif e.key_name == "CtrlV" then
            local pastetext = os.pbpaste()
            if pastetext then
                self:text_set(self:text() .. pastetext)
            end
            return true
        elseif e.key_code > 0x1f and e.key_code < 0xf8 then
            self:text_set(self:text() .. string.char(e.key_code))
            return true
        end
    end

    -- do textarea event
    return textarea.on_event(self, e)
end

-- return module
return textedit
