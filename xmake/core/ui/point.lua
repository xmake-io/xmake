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
-- @file        point.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: point.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local object = require("ui/object")

-- define module
local point = point or object { _init = {"x", "y"} }

-- add delta x and y
function point:addxy(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    return self
end

-- add point
function point:add(p)
    return self:addxy(p.x, p.y)
end

-- sub delta x and y
function point:subxy(dx, dy)
    return self:addxy(-dx, -dy)
end

-- sub point
function point:sub(p)
    return self:addxy(-p.x, -p.y)
end

-- p1 + p2
function point:__add(p)
    local np = self()
    np.x = np.x + p.x
    np.y = np.y + p.y
    return np
end

-- p1 - p2
function point:__sub(p)
    local np = self()
    np.x = np.x - p.x
    np.y = np.y - p.y
    return np
end

-- -p
function point:__unm()
    local p = self()
    p.x = -p.x
    p.y = -p.y
    return p
end

-- p1 == p2?
function point:__eq(p)
    return self.x == p.x and self.y == p.y
end

-- tostring(p)
function point:__tostring()
    return '(' .. self.x .. ', ' .. self.y .. ')'
end

-- p1 .. p2
function point.__concat(op1, op2)
    if type(op1) == 'string' then
        return op1 .. op2:__tostring()
    elseif type(op2) == 'string' then
        return op1:__tostring() .. op2
    else
        return op1:__tostring() .. op2:__tostring()
    end
end

-- return module
return point
