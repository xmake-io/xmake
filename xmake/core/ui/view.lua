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
function view:new(bounds)

    -- create instance
    self = self()

    -- init view
    self:init(bounds)

    -- done
    return self
end

-- init view
function view:init(bounds)

    -- check
    assert(type(bounds) == 'table')

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

    -- init bounds and window
    self:bounds_set(bounds)
end

-- exit view
function view:exit()

    -- close window
    if self._window then
        self._window:close()
        self._window = nil
    end
end

-- set window bounds
function view:bounds_set(bounds)

    -- close the previous windows first
    if self._window then
        self._window:close()
    end

    -- init bounds
    self._bounds = bounds()

    -- create a new window
    local size = bounds:size()
    self._window = curses.new_pad(size.y > 0 and size.y or 1, size.x > 0 and size.x or 1)
    assert(self._window, "cannot create window!")

    -- disable cursor
    self._window:leaveok(true)
end

-- get window bounds
function view:bounds()
    return self._bounds()
end

-- get the parent view
function view:parent()
    return self._PARENT
end

-- get the view canvas
function view:canvas()
    if not self._CANVAS then
        self._CANVAS = canvas:new(self, self._window)
    end
    return self._CANVAS
end

-- on draw window
function view:on_draw()
    self:canvas():clear()
end

-- refresh view in parent window
function view:refresh()
    self:on_draw()
    self:redraw(true)
end

-- redraw view
function view:redraw(on_parent)

    -- redraw this child view on parent view (group)
    if on_parent and self:parent() then
        self:lock()
        local v = self
        while v:parent() do
            v:parent():draw_child(v)
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

-- return module
return view
