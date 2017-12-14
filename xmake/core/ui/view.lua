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
-- @file        view.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: view.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local object = require("ui/object")
local canvas = require("ui/canvas")
local curses = require("ui/curses")

-- define module
local view = view or object()

-- new view instance
function view:new(name, bounds)

    -- create instance
    self = self()

    -- init view
    self:init(name, bounds)

    -- done
    return self
end

-- init view
function view:init(name, bounds)

    -- check
    assert(name and type(bounds) == 'table')

    -- init state
    local state          = object()
    state.visible        = false     -- view visibility
    state.cursor_visible = false     -- cursor visibility
    state.block_cursor   = false     -- block cursor
    state.selected       = false     -- current selected window inside group
    state.focused        = false     -- true if parent is also focused
    state.disabled       = false     -- view disabled
    state.modal          = false     -- is modal view?
    self._STATE          = state

    -- init options
    local options        = object()
    options.selectable   = false     -- true if window can be selected
    options.top_select   = false     -- if true, selecting window will bring it to front
    options.pre_event    = false     -- receive event before focused window
    options.post_event   = false     -- receive event after focused window
    options.centerx      = false     -- center horizontaly when inserting in parent
    options.centery      = false     -- center verticaly when inserting in parent
    options.validate     = false     -- validate
    self._OPTIONS        = options

    -- init name
    self._NAME = name

    -- init bounds and window
    self:bounds_set(bounds)
end

-- exit view
function view:exit()

    -- close window
    if self:window() then
        self:window():close()
        self._WINDOW = nil
    end
end

-- get view name
function view:name()
    return self._NAME
end

-- set window bounds
function view:bounds_set(bounds)

    -- close the previous windows first
    if self:window() then
        self:window():close()
    end

    -- init size and bounds
    self._SIZE = bounds:size()
    self._BOUNDS = bounds()

    -- create a new window
    self._WINDOW = curses.new_pad(self:height() > 0 and self:height() or 1, self:width() > 0 and self:width() or 1)
    assert(self._WINDOW, "cannot create window!")

    -- disable cursor
    self:window():leaveok(true)
end

-- get view width
function view:width()
    return self._SIZE.x
end

-- get view height
function view:height()
    return self._SIZE.y
end

-- get view size
function view:size()
    return self._SIZE
end

-- get view bounds
function view:bounds()
    return self._BOUNDS
end

-- get the parent view
function view:parent()
    return self._PARENT
end

-- set the parent view
function view:parent_set(parent)
    self._PARENT = parent
end

-- get the view window
function view:window()
    return self._WINDOW
end

-- get the view canvas
function view:canvas()
    if not self._CANVAS then
        self._CANVAS = canvas:new(self, self:window())
    end
    return self._CANVAS
end

-- draw view
function view:draw()
    self:canvas():clear()
end

-- refresh view in parent window
function view:refresh()
    self:draw()
    self:redraw(true)
end

-- redraw view
function view:redraw(on_parent)

    -- redraw this child view on parent view (group)
    if on_parent and self:parent() then
        self:lock()
        local v = self
        while v:parent() do
            v:parent():_draw_overlap(v)
            v = v:parent()
        end
        self:unlock()
    end
end

-- lock view
function view:lock()
end

-- unlock view
function view:unlock()
end

-- show view?
function view:show(visible)
    if self:state("visible") ~= visible then
        self:state_set("visible", visible)
    end
end

-- get state
function view:state(name)
    return self._STATE[name]
end

-- set state
function view:state_set(name, enable)

    -- state is not changed?
    enable = enable or false
    if self:state(name) == enable then
        return 
    end

    -- change state
    self._STATE[name] = enable

    -- update visible?
    if name == "visible" then
        self:redraw(true)
    end
end

-- get option
function view:option(name)
    return self._OPTIONS[name]
end

-- set option
function view:option_set(name, enable)

    -- state is not changed?
    enable = enable or false
    if self:option(name) == enable then
        return 
    end

    -- set option
    self._OPTIONS[name] = enable
end

-- tostring(view)
function view:__tostring()
    return string.format("<%s %s>", self:name(), tostring(self:bounds()))
end

-- return module
return view
