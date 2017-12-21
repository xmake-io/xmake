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
-- @file        group.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: group.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local log    = require("ui/log")
local view   = require("ui/view")
local rect   = require("ui/rect")
local event  = require("ui/event")
local point  = require("ui/point")
local curses = require("ui/curses")
local dlist  = require("base/dlist")

-- define module
local group = group or view()

-- init group
function group:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

    -- mark as selectable
    self:option_set("selectable", true)

    -- init child views
    self._VIEWS = dlist()
end

-- exit group
function group:exit()

    -- exit view
    view.exit(self)
end

-- get all child views
function group:views()
    return self._VIEWS:items()
end

-- get views count
function group:count()
    return self._VIEWS:size()
end

-- is empty?
function group:empty()
    return self._VIEWS:empty()
end

-- get the first view
function group:first()
    return self._VIEWS:first()
end

-- get the next view
function group:next(v)
    return self._VIEWS:next(v)
end

-- get the previous view
function group:prev(v)
    return self._VIEWS:prev(v)
end

-- get the current selected child view
function group:current()
    return self._CURRENT
end

-- insert view
function group:insert(v)

    -- check
    assert(not v:parent() or v:parent() == self)

    -- this view has been inserted into this group? remove it first
    if v:parent() == self then
        self:remove(v)
    end

    -- center this view if centerx or centery are set
    local bounds = v:bounds()
    local org = point {bounds.sx, bounds.sy}
    if v:option("centerx") then
        org.x = math.floor((self:width() - v:width()) / 2)
    end
    if v:option("centery") then
        org.y = math.floor((self:height() - v:height()) / 2)
    end
    bounds:move(org.x - bounds.sx, org.y - bounds.sy)
    v:bounds_set(bounds)

    -- insert this view
    self._VIEWS:push(v)

    -- set it's parent view
    v:parent_set(self)

    -- set application
    v:application_set(self:application())

    -- select this view
    if v:option("selectable") then
        self:select(v)
    end
end

-- remove view
function group:remove(v)

    -- check
    assert(v:parent() == self)

    -- lock
    self:lock()

    -- hide this view first
    v:show(false)

    -- remove view
    self._VIEWS:remove(v)

    -- select next view
    if self:current() == v then
        self._CURRENT = nil
        self:select_next()
    end

    -- unlock
    self:unlock()
end

-- select the child view
function group:select(v)

    -- check
    assert(v == nil or (v:parent() == self and v:option("selectable")))

    -- get the current selected view
    local current = self:current()
    if v == current then 
        return 
    end

    -- undo the previous selected view
    if current then

        -- undo the current view first
        if self:state("focused") then
            current:state_set("focused", false)
        end
        current:state_set("selected", false)
    end

    -- update the current selected view
    self._CURRENT = v

    -- update the new selected view
    if v then

        -- modify view order and mark this view as top
        if v:option("top_select") then
            self._VIEWS:remove(v)
            self._VIEWS:push(v)
        end

        -- select and focus this view
        v:state_set('selected', true)
        if self:state("focused") then
            v:state_set('focused', true)
        end
    end
end

-- select the next view
function group:select_next(forward, start)

    -- is empty?
    if self:empty() then
        return 
    end

    -- get current view
    local current = start or self:current() or self:first()

    -- forward?
    if forward then
        local next = self:next(current)
        while next ~= current do
            if next:option("selectable") and next:state("visible") then
                self:select(next)
                break
            end
            next = self:next(next)
        end
    else
        local prev = self:prev(current)
        while prev ~= current do
            if prev:option("selectable") and prev:state("visible") then
                self:select(prev)
                break
            end
            prev = self:prev(prev)
        end
    end
end

-- on event
function group:event_on(e)

    -- is empty views?
    if self:empty() then
        return 
    end

    -- send event to all child views
    for v in self:views() do
        if v:event_need(e) then
            v:event_on(e)
        end
    end
end

-- draw group 
function group:draw()

    -- draw it
    if self:state("redraw") then

        -- draw group background first
        view.draw(self)

        -- draw all child views
        for v in self:views() do
            if v:state("visible") then
                v:draw()
                v:state_set("redraw", false)
            end
        end

        -- clear mark
        self:state_set("redraw", false)
    else

        -- only draw child views
        for v in self:views() do
            if v:state("visible") and v:state("redraw") then
                v:draw()
                v:state_set("redraw", false)
            end
        end
    end
end

-- refresh group
function group:refresh()

    -- need not refresh? do not refresh it
    if not self:state("refresh") then
        return 
    end

    -- refresh all child views
    for v in self:views() do
        if v:state("refresh") then
            v:refresh()
            v:state_set("refresh", false)
        end
    end

    -- refresh it
    view.refresh(self)

    -- clear mark
    self:state_set("refresh", false)
end

-- dump all views
function group:dump()
    log:print("%s", self:_tostring(1))
end

-- tostring(group, level)
function group:_tostring(level)
    local str = ""
    if self.views then  
        str = str .. string.format("<%s %s>", self:name(), tostring(self:bounds()))
        if not self:empty() then
            str = str .. "\n"
        end
        for v in self:views() do  
            for l = 1, level do
                str = str .. "    "
            end
            str = str .. group._tostring(v, level + 1) .. "\n"
        end  
    else
        str = tostring(self)
    end
    return str
end

-- tostring(group)
function group:__tostring()
    return string.format("<group(%s) %s>", self:name(), tostring(self:bounds()))
end


-- return module
return group
