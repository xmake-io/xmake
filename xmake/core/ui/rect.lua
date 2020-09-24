
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
-- @file        rect.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: rect.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local point  = require("ui/point")
local object = require("ui/object")

-- define module
local rect = rect or object { _init = {"sx", "sy", "ex", "ey"} }

-- make rect
function rect:new(x, y, w, h)
    return rect { x, y, x + w, y + h }
end

-- get rect size
function rect:size()
    return point { self.ex - self.sx, self.ey - self.sy }
end

-- get width
function rect:width()
    return self.ex - self.sx
end

-- get height
function rect:height()
    return self.ey - self.sy
end

-- resize rect
function rect:resize(w, h)
    self.ex = self.sx + w
    self.ey = self.sy + h
end

-- move rect
function rect:move(dx, dy)
    self.sx = self.sx + dx
    self.sy = self.sy + dy
    self.ex = self.ex + dx
    self.ey = self.ey + dy
    return self
end

-- move rect to the given position
function rect:move2(x, y)
    local w = self.ex - self.sx
    local h = self.ey - self.sy
    self.sx = x
    self.sy = y
    self.ex = x + w
    self.ey = y + h
    return self
end

-- move top right corner of the rect
function rect:moves(dx, dy)
    self.sx = self.sx + dx
    self.sy = self.sy + dy
    return self
end

-- move bottom left corner of the rect
function rect:movee(dx, dy)
    self.ex = self.ex + dx
    self.ey = self.ey + dy
    return self
end

-- expand rect area
function rect:grow(dx, dy)
    self.sx = self.sx - dx
    self.sy = self.sy - dy
    self.ex = self.ex + dx
    self.ey = self.ey + dy
    return self
end

-- is intersect?
function rect:is_intersect(r)
    return not self():intersect(r):empty()
end

-- set rect with shared area between this rect and a given rect
function rect:intersect(r)
    self.sx = math.max(self.sx, r.sx)
    self.sy = math.max(self.sy, r.sy)
    self.ex = math.min(self.ex, r.ex)
    self.ey = math.min(self.ey, r.ey)
    return self
end

-- get rect with shared area between two rects: local rect_new = r1 / r2
function rect:__div(r)
    return self():intersect(r)
end

-- set union rect
function rect:union(r)
    self.sx = math.min(self.sx, r.sx)
    self.sy = math.min(self.sy, r.sy)
    self.ex = math.max(self.ex, r.ex)
    self.ey = math.max(self.ey, r.ey)
    return self
end

-- get union rect: local rect_new = r1 + r2
function rect:__add(r)
    return self():union(r)
end

-- r1 == r1?
function rect:__eq(r)
    return
        self.sx == r.sx and
        self.sy == r.sy and
        self.ex == r.ex and
        self.ey == r.ey
end

-- contains the given point in rect?
function rect:contains(x, y)
    return x >= self.sx and x < self.ex and y >= self.sy and y < self.ey
end

-- empty rect?
function rect:empty()
    return self.sx >= self.ex or self.sy >= self.ey
end

-- tostring(r)
function rect:__tostring()
    if self:empty() then
        return '[]'
    end
    return string.format("[%d, %d, %d, %d]", self.sx, self.sy, self.ex, self.ey)
end

-- r1 .. r2
function rect.__concat(op1, op2)
    if type(op1) == 'string' then
        return op1 .. op2:__tostring()
    elseif type(op2) == 'string' then
        return op1:__tostring() .. op2
    else
        return op1:__tostring() .. op2:__tostring()
    end
end

-- return module
return rect
