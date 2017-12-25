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

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local object = require("ui/object")
local canvas = require("ui/canvas")
local curses = require("ui/curses")

-- define module
local view = view or object()

-- new view instance
function view:new(name, bounds, ...)

    -- create instance
    self = self()

    -- init view
    self:init(name, bounds, ...)

    -- done
    return self
end

-- init view
function view:init(name, bounds)

    -- check
    assert(name and type(bounds) == 'table')

    -- init state
    local state          = object()
    state.visible        = true      -- view visibility
    state.selected       = false     -- current selected window inside group
    state.focused        = false     -- true if parent is also focused
    state.redraw         = true      -- need redraw 
    state.refresh        = true      -- need refresh
    self._STATE          = state

    -- init options
    local options        = object()
    options.selectable   = false     -- true if window can be selected
    options.top_select   = false     -- if true, selecting window will bring it to front
    self._OPTIONS        = options

    -- init attributes
    local attrs          = object()
    self._ATTRS          = attrs

    -- init needed events type
    local events         = object()
    self._EVENTS         = events

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

-- get the application 
function view:application()
    return self._APPLICATION
end

-- set the application 
function view:application_set(app)
    self._APPLICATION = app
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

    -- trace
    log:print("%s: draw ..", self)

    -- clear view
    self:canvas():clear()

    -- draw background
    local background = self:background()
    if background then
        self:canvas():attr(background):move(0, 0):write(string.rep(' ', self:width() * self:height()))
    end
end

-- refresh view
function view:refresh()

    -- refresh to the parent view
    local parent = self:parent()
    if parent then

        -- clip bounds with the parent view
        local bounds = self:bounds()
        local r = bounds():intersect(rect{0, 0, parent:width(), parent:height()})
        if not r:empty() then

            -- trace
            log:print("%s: refresh to %s(%d, %d, %d, %d) ..", self, parent:name(), r.sx, r.sy, r.ex, r.ey)

            -- copy this view to parent view
            self:window():copy(parent:window(), 0, 0, r.sy, r.sx, r.ey - 1, r.ex - 1)
        end
    end
end

-- show view?
function view:show(visible)
    if self:state("visible") ~= visible then
        self:state_set("visible", visible)
        self:invalidate()
    end
end

-- invalidate view to redraw it
function view:invalidate()
    self:_mark_redraw()
end

-- on event (abstract)
function view:event_on(e)
end

-- get the current event
function view:event()
    return self:parent() and self:parent():event()
end

-- put an event to view
function view:event_put(e)
    return self:parent() and self:parent():event_put(e)
end

-- need this event?
function view:event_need(e)
    return self._EVENTS[e.type]
end

-- register an event type
function view:event_register(etype)
    self._EVENTS[etype] = true
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

-- get attribute
function view:attr(name)
    return self._ATTRS[name]
end

-- set attribute
function view:attr_set(name, value)
    self._ATTRS[name] = value
    self:invalidate()
end

-- get background
function view:background()
    return self:attr("background")
end

-- set background
function view:background_set(color)
    self:attr_set("background", color)
end

-- need redraw view
function view:_mark_redraw()

    -- need redraw it
    self:state_set("redraw", true)

    -- need redraw it's parent view if this view is invisible
    if not self:state("visible") and self:parent() then
        self:parent():_mark_redraw()
    end
end

-- need refresh view
function view:_mark_refresh()

    -- need refresh it
    if self:state("visible") then
        self:state_set("refresh", true)
    end

    -- need refresh it's parent view 
    if self:parent() then
        self:parent():_mark_refresh()
    end
end

-- tostring(view)
function view:__tostring()
    return string.format("<view(%s) %s>", self:name(), tostring(self:bounds()))
end

-- return module
return view
