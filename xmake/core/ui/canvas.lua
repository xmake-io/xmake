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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        canvas.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: canvas.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local object = require("ui/object")
local curses = require("ui/curses")

-- define module
local canvas = canvas or object()

-- new canvas instance
function canvas:new(view, window)

    -- create instance
    self = self()

    -- save view and window
    self._view = view
    self._window = window
    assert(view and window, "cannot new canvas instance without view and window!")

    -- set the default attributes
    self:attr()

    -- done
    return self
end

-- clear canvas
function canvas:clear()
    self._window:clear()
    return self
end

-- move canvas to the given position
function canvas:move(x, y)
    self._window:move(y, x)
    return self
end

-- get canvas border
function canvas:border()
    self._window:border()
    return self
end

-- write a character to canvas
function canvas:write_ch(ch)
    self._window:addch(ch)
    return self
end

-- write an acs character
function canvas:write_acs(ch)
    return self:write_ch(curses.acs(ch))
end

-- write a string to canvas
function canvas:write(str, len)
    if type(str) == 'string' then
        self._window:addstr(str, len)
    else
        self._window:addchstr(str._line, len)
    end
    return self
end

-- set canvas attributes
--
-- set attr:    canvas:attr("bold")
-- add attr:    canvas:attr("bold", true)
-- remove attr: canvas:attr("bold", false)
--
function canvas:attr(attrs, modify)

    -- calculate the attributes
    local attr = curses.calc_attr(attrs)
    if modify == nil then
        self._window:attrset(attr)
    elseif modify == false then
        self._window:attroff(attr)
    else
        self._window:attron(attr)
    end
    return self
end

--[[
function canvas:line(length)
    return Line:create(length)
end


function Line:create(length)
    self = self()
    self._length = length
    self._line = curses.new_chstr(length)
    return self
end

function Line:__len()
    return self._length
end

function Line:ch(offset, char, attrs, length)
    self._line:set_ch(offset, char, attrs and calc_attr(attrs), length)
    return self
end

function Line:acs(offset, char, attrs, length)
    return self:ch(offset, acs(char), attrs, length)
end

function Line:str(offset, str, attrs, rep)
    self._line:set_str(offset, str, calc_attr(attrs), rep)
    return self
end
]]

-- return module
return canvas
