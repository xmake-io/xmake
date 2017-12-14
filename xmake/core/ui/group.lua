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
local view   = require("ui/view")
local rect   = require("ui/rect")
local point  = require("ui/point")
local curses = require("ui/curses")
local dlist  = require("base/dlist")

-- define module
local group = group or view()

-- init group
function group:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

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

-- insert view
function group:insert(v)

    -- check
    assert(not v:parent() or v:parent() == self)

    -- lock
    self:lock()

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

    -- TODO select this view
    if v:option("selectable") then
--        self:select(v)
    end

    -- draw and show this view
    v:draw()
    v:show(true)

    -- unlock
    self:unlock()
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

    -- TODO select next view

    -- unlock
    self:unlock()
end

-- execute group
function group:execute()
end

-- draw group 
function group:draw()

    -- draw sub views
    for v in self:views() do
        if v:state("visible") then
            v:draw()
        end
    end
end

-- refresh group in parent window
function group:refresh()
    self:lock()
    self:draw()
    self:redraw(true)
    self:unlock()
end

-- draw this child view
function group:_draw_child(v)

    -- draw it if this child view is in a vaild bounds
    local bounds = v:bounds()
    local r = bounds():intersect(rect{0, 0, self:width(), self:height()})
    if r.ex > r.sx and r.ey > r.sy then

        -- TODO
        -- copy this child view to group window
        local sx = bounds.sx; sx = sx > 0 and 0 or -sx
        local sy = bounds.sy; sy = sy > 0 and 0 or -sy
        v:window():copy(self:window(), sy, sx, r.sy, r.sx, r.ey - 1, r.ex - 1)
    end
end

-- draw overlapping views about this child view
function group:_draw_overlap(v)

    -- lock
    self:lock()

    -- draw all overlapping areas
    local bounds = v:bounds()
    while v do

        -- check for overlapping areas
        if v:state("visible") and v:bounds():is_intersect(bounds) then

            -- draw this child view
            self:_draw_child(v)

            -- if they overlap, join them. 
            -- use the resulting rectangle to check for overlapping areas on the following windows
            bounds:union(v:bounds())
        end

        -- get the next view
        v = self:next(v)
    end

    -- unlock
    self:unlock()
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
    return self:_tostring(1)
end


-- return module
return group
