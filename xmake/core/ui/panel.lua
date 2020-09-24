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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        panel.lua
--

-- load modules
local log    = require("ui/log")
local view   = require("ui/view")
local rect   = require("ui/rect")
local event  = require("ui/event")
local point  = require("ui/point")
local curses = require("ui/curses")
local dlist  = require("base/dlist")

-- define module
local panel = panel or view()

-- init panel
function panel:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

    -- mark as panel
    self:type_set("panel")

    -- mark as selectable
    self:option_set("selectable", true)

    -- init child views
    self._VIEWS = dlist.new()

    -- init views cache
    self._VIEWS_CACHE = {}
end

-- get all child views
function panel:views()
    return self._VIEWS:items()
end

-- get views count
function panel:count()
    return self._VIEWS:size()
end

-- is empty?
function panel:empty()
    return self._VIEWS:empty()
end

-- get the first view
function panel:first()
    return self._VIEWS:first()
end

-- get the next view
function panel:next(v)
    return self._VIEWS:next(v)
end

-- get the previous view
function panel:prev(v)
    return self._VIEWS:prev(v)
end

-- get the current selected child view
function panel:current()
    return self._CURRENT
end

-- get view from the given name
function panel:view(name)
    return self._VIEWS_CACHE[name]
end

-- center view
function panel:center(v, opt)

    -- center this view if centerx or centery are set
    local bounds = v:bounds()
    local center = false
    local org = point {bounds.sx, bounds.sy}
    if opt and opt.centerx then
        org.x = math.floor((self:width() - v:width()) / 2)
        center = true
    end
    if opt and opt.centery then
        org.y = math.floor((self:height() - v:height()) / 2)
        center = true
    end
    if center then
        bounds:move(org.x - bounds.sx, org.y - bounds.sy)
        v:invalidate(true)
    end
end

-- insert view
function panel:insert(v, opt)

    -- check
    assert(not v:parent() or v:parent() == self)
    assert(not self:view(v:name()), v:name() .. " has been in this panel!")

    -- this view has been inserted into this panel? remove it first
    if v:parent() == self then
        self:remove(v)
    end

    -- center this view if centerx or centery are set
    self:center(v, opt)

    -- insert this view
    self._VIEWS:push(v)

    -- cache this view
    self._VIEWS_CACHE[v:name()] = v

    -- set it's parent view
    v:parent_set(self)

    -- select this view
    if v:option("selectable") then
        self:select(v)
    end

    -- invalidate it
    self:invalidate()
end

-- remove view
function panel:remove(v)

    -- check
    assert(v:parent() == self)

    -- remove view
    self._VIEWS:remove(v)
    self._VIEWS_CACHE[v:name()] = nil

    -- clear parent
    v:parent_set(nil)

    -- select next view
    if self:current() == v then
        self:select_next(nil, true)
    end

    -- invalidate it
    self:invalidate()
end

-- clear views
function panel:clear()

    -- clear parents
    for v in self:views() do
        v:parent_set(nil)
    end

    -- clear views and cache
    self._VIEWS:clear()
    self._VIEWS_CACHE = {}

    -- reset the current view
    self._CURRENT = nil

    -- invalidate
    self:invalidate()
end

-- select the child view
function panel:select(v)

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

        -- select and focus this view
        v:state_set("selected", true)
        if self:state("focused") then
            v:state_set("focused", true)
        end
    end

    -- ok
    return v
end

-- select the next view
function panel:select_next(start, reset)

    -- is empty?
    if self:empty() then
        return
    end

    -- reset?
    if reset then
        self._CURRENT = nil
    end

    -- get current view
    local current = start or self:current()

    -- select the next view
    local next = self:next(current)
    while next ~= current do
        if next and next:option("selectable") and next:state("visible") then
            return self:select(next)
        end
        next = self:next(next)
    end
end

-- select the previous view
function panel:select_prev(start)

    -- is empty?
    if self:empty() then
        return
    end

    -- reset?
    if reset then
        self._CURRENT = nil
    end

    -- get current view
    local current = start or self:current()

    -- select the previous view
    local prev = self:prev(current)
    while prev ~= current do
        if prev and prev:option("selectable") and prev:state("visible") then
            return self:select(prev)
        end
        prev = self:prev(prev)
    end
end

-- on event
function panel:on_event(e)

    -- select view?
    if e.type == event.ev_keyboard then
        -- @note we also use '-' to switch them on termux without right/left and
        -- we cannot use tab, because we still need swith views on windows. e.g. inputdialog
        -- @see https://github.com/tboox/ltui/issues/11
        if e.key_name == "Right" or e.key_name == "-" then
            return self:select_next()
        elseif e.key_name == "Left" then
            return self:select_prev()
        end
    end
end

-- set state
function panel:state_set(name, enable)
    view.state_set(self, name, enable)
    if name == "focused" and self:current() then
        self:current():state_set(name, enable)
    end
    return self
end

-- draw panel
function panel:on_draw(transparent)

    -- redraw panel?
    local redraw = self:state("redraw")

    -- draw panel background first
    if redraw then
        view.on_draw(self, transparent)
    end

    -- draw all child views
    for v in self:views() do
        if redraw then
            v:state_set("redraw", true)
        end
        if v:state("visible") and (v:state("redraw") or v:type() == "panel") then
            v:on_draw(transparent)
        end
    end
end

-- resize panel
function panel:on_resize()

    -- resize panel
    view.on_resize(self)

    -- resize all child views
    for v in self:views() do
        v:state_set("resize", true)
        if v:state("visible") then
            v:on_resize()
        end
    end
end

-- refresh panel
function panel:on_refresh()

    -- need not refresh? do not refresh it
    if not self:state("refresh") or not self:state("visible") then
        return
    end

    -- refresh all child views
    for v in self:views() do
        if v:state("refresh") then
            v:on_refresh()
            v:state_set("refresh", false)
        end
    end

    -- refresh it
    view.on_refresh(self)

    -- clear mark
    self:state_set("refresh", false)
end

-- dump all views
function panel:dump()
    log:print("%s", self:_tostring(1))
end

-- tostring(panel, level)
function panel:_tostring(level)
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
            str = str .. panel._tostring(v, level + 1) .. "\n"
        end
    else
        str = tostring(self)
    end
    return str
end

-- tostring(panel)
function panel:__tostring()
    return string.format("<panel(%s) %s>", self:name(), tostring(self:bounds()))
end


-- return module
return panel
