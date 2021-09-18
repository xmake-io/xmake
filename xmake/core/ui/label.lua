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
-- @file        label.lua
--

-- load modules
local log       = require("ui/log")
local view      = require("ui/view")
local event     = require("ui/event")
local action    = require("ui/action")
local curses    = require("ui/curses")
local bit       = require("base/bit")

-- define module
local label = label or view()

-- init label
function label:init(name, bounds, text)

    -- init view
    view.init(self, name, bounds)

    -- init text
    self:text_set(text)

    -- init text attribute
    self:textattr_set("black")
end

-- draw view
function label:on_draw(transparent)

    -- draw background
    view.on_draw(self, transparent)

    -- get the text attribute value
    local textattr = self:textattr_val()

    -- draw text string
    local str = self:text()
    if str and #str > 0 and textattr then
        self:canvas():attr(textattr):move(0, 0):putstrs(self:splitext(str))
    end
end

-- get text
function label:text()
    return self._TEXT
end

-- set text
function label:text_set(text)

    -- set text
    text = text or ""
    local changed = self._TEXT ~= text
    self._TEXT = text

    -- do action
    if changed then
        self:action_on(action.ac_on_text_changed)
    end
    self:invalidate()
    return self
end

-- get text attribute
function label:textattr()
    return self:attr("textattr")
end

-- set text attribute, e.g. textattr_set("yellow onblue bold")
function label:textattr_set(attr)
    return self:attr_set("textattr", attr)
end

-- get the current text attribute value
function label:textattr_val()

    -- get text attribute
    local textattr = self:textattr()
    if not textattr then
        return
    end

    -- no text background? use view's background
    if self:background() and not textattr:find("on") then
        textattr = textattr .. " on" .. self:background()
    end

    -- attempt to get the attribute value from the cache first
    self._TEXTATTR = self._TEXTATTR or {}
    local value = self._TEXTATTR[textattr]
    if value then
        return value
    end

    -- update the cache
    value = curses.calc_attr(textattr:split("%s"))
    self._TEXTATTR[textattr] = value
    return value
end

-- split text by width
function label:splitext(text, width)

    -- get width
    width = width or self:width()

    -- split text first
    local result = {}
    local lines = text:split('\n', {strict = true})
    for idx = 1, #lines do
        local line = lines[idx]
        while #line > width do
            local size = 0
            for i = 1, #line do
                if bit.band(line:byte(i), 0xc0) ~= 0x80 then
                    size = size + line:wcwidth(i)
                    if size > width then
                        table.insert(result, line:sub(1, i - 1))
                        line = line:sub(i)
                        break
                    end
                end
            end
            if size <= width then
                break
            end
        end
        table.insert(result, line)
    end
    return result
end

-- return module
return label
