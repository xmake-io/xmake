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
-- @file        view.lua
--

-- load modules
local table  = require("base/table")
local log    = require("ui/log")
local rect   = require("ui/rect")
local point  = require("ui/point")
local object = require("ui/object")
local canvas = require("ui/canvas")
local curses = require("ui/curses")
local action = require("ui/action")

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

    -- init type
    self._TYPE           = "view"

    -- init state
    local state          = object()
    state.visible        = true      -- view visibility
    state.cursor_visible = false     -- cursor visibility
    state.block_cursor   = false     -- block cursor
    state.selected       = false     -- is selected?
    state.focused        = false     -- is focused?
    state.redraw         = true      -- need redraw
    state.on_refresh     = true      -- need refresh
    state.on_resize      = true      -- need resize
    self._STATE          = state

    -- init options
    local options        = object()
    options.selectable   = false     -- true if window can be selected
    self._OPTIONS        = options

    -- init attributes
    self._ATTRS          = object()

    -- init actions
    self._ACTIONS        = object()

    -- init extras
    self._EXTRAS         = object()

    -- init name
    self._NAME           = name

    -- init cursor
    self._CURSOR         = point{0, 0}

    -- init bounds and window
    self:bounds_set(bounds)
end

-- exit view
function view:exit()

    -- close window
    if self._WINDOW then
        self._WINDOW:close()
        self._WINDOW = nil
    end
end

-- get view name
function view:name()
    return self._NAME
end

-- get view bounds
function view:bounds()
    return self._BOUNDS
end

-- set window bounds
function view:bounds_set(bounds)
    if bounds and self:bounds() ~= bounds then
        self._BOUNDS = bounds()
        self:invalidate(true)
    end
end

-- get view width
function view:width()
    return self:bounds():width()
end

-- get view height
function view:height()
    return self:bounds():height()
end

-- get view size
function view:size()
    return self:bounds():size()
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
    if not self._APPLICATION then
        local app = self
        while app:parent() do
            app = app:parent()
        end
        self._APPLICATION = app
    end
    return self._APPLICATION
end

-- get the view window
function view:window()
    if not self._WINDOW then

        -- create window
        self._WINDOW = curses.new_pad(self:height() > 0 and self:height() or 1, self:width() > 0 and self:width() or 1)
        assert(self._WINDOW, "cannot create window!")

        -- disable cursor
        self._WINDOW:leaveok(true)
    end
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
function view:on_draw(transparent)

    -- trace
    log:print("%s: draw (transparent: %s) ..", self, tostring(transparent))

    -- draw background
    if not transparent then
        local background = self:background()
        if background then
            background = curses.color_pair(background, background)
            self:canvas():attr(background):move(0, 0):putchar(' ', self:width() * self:height())
        else
            self:canvas():clear()
        end
    end

    -- clear mark
    self:state_set("redraw", false)
    self:_mark_refresh()
end

-- refresh view
function view:on_refresh()

    -- refresh to the parent view
    local parent = self:parent()
    if parent and self:state("visible") then

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

-- resize bounds of inner child views (abstract)
function view:on_resize()

    -- trace
    log:print("%s: resize ..", self)

    -- close the previous windows first
    if self._WINDOW then
        self._WINDOW:close()
        self._WINDOW = nil
    end

    -- need renew canvas
    self._CANVAS = nil

    -- clear mark
    self:state_set("resize", false)

    -- do action
    self:action_on(action.ac_on_resized)
end

-- show view?
--
-- .e.g
-- v:show(false)
-- v:show(true, {focused = true})
--
function view:show(visible, opt)
    if self:state("visible") ~= visible then
        local parent = self:parent()
        if parent and parent:current() == self and not visible then
            parent:select_next(nil, true)
        elseif parent and visible and opt and opt.focused then
            parent:select(self)
        end
        self:state_set("visible", visible)
        self:invalidate()
    end
end

-- invalidate view to redraw it
function view:invalidate(bounds)
    if bounds then
        self:_mark_resize()
    end
    self:_mark_redraw()
end

-- on event (abstract)
--
-- @return true: done and break dispatching, false/nil: continous to dispatch to other views
--
function view:on_event(e)
end

-- get the current event
function view:event()
    return self:parent() and self:parent():event()
end

-- put an event to view
function view:put_event(e)
    return self:parent() and self:parent():put_event(e)
end

-- get type
function view:type()
    return self._TYPE
end

-- set type
function view:type_set(t)
    self._TYPE = t or "view"
    return self
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
        return self
    end

    -- change state
    self._STATE[name] = enable
    return self
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
    return self
end

-- get extra data
function view:extra(name)
    return self._EXTRAS[name]
end

-- set extra data
function view:extra_set(name, value)
    self._EXTRAS[name] = value
    return self
end

-- set action
function view:action_set(name, on_action)
    self._ACTIONS[name] = on_action
    return self
end

-- add action
function view:action_add(name, on_action)
    self._ACTIONS[name] = table.join(table.wrap(self._ACTIONS[name]), on_action)
    return self
end

-- do action
function view:action_on(name, ...)
    local on_action = self._ACTIONS[name]
    if on_action then
        if type(on_action) == "string" then
            -- send command
            if self:application() then
                self:application():send(on_action)
            end
        elseif type(on_action) == "function" then
            -- do action script
            return on_action(self, ...)
        elseif type(on_action) == "table" then
            for _, on_action_val in ipairs(on_action) do
                -- we cannot uses the return value of action for multi-actions
                if type(on_action_val) == "function" then
                    on_action_val(self, ...)
                end
            end
        end
    end
end

-- get cursor position
function view:cursor()
    return self._CURSOR
end

-- move cursor to the given position
function view:cursor_move(x, y)
    self._CURSOR = point{ self:_limit(x, 0, self:width() - 1), self:_limit(y, 0, self:height() - 1) }
    return self
end

-- show cursor?
function view:cursor_show(visible)
    if self:state("cursor_visible") ~= visible then
        self:state_set("cursor_visible", visible)
    end
    return self
end

-- get background
function view:background()
    local background = self:attr("background")
    if not background and self:parent() then
        background = self:parent():background()
    end
    return background
end

-- set background, .e.g background_set("blue")
function view:background_set(color)
    return self:attr_set("background", color)
end

-- limit value range
function view:_limit(value, minval, maxval)
    return math.min(maxval, math.max(value, minval))
end

-- need resize view
function view:_mark_resize()

    -- have been marked?
    if self:state("resize") then
        return
    end

    -- trace
    log:print("%s: mark as resize", self)

    -- need resize it
    self:state_set("resize", true)

    -- @note we need trigger on_resize() of the root view and pass it to this subview
    if self:parent() then
        self:parent():invalidate(true)
    end
end

-- need redraw view
function view:_mark_redraw()

    -- have been marked?
    if self:state("redraw") then
        return
    end

    -- trace
    log:print("%s: mark as redraw", self)

    -- need redraw it
    self:state_set("redraw", true)

    -- need redraw it's parent view if this view is invisible
    if not self:state("visible") and self:parent() then
        self:parent():_mark_redraw()
    end
end

-- need refresh view
function view:_mark_refresh()

    -- have been marked?
    if self:state("refresh") then
        return
    end

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
