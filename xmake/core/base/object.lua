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
-- @file        object.lua
--

-- define module: object
local object = object or {}

-- taken from 'std' library: http://luaforge.net/projects/stdlib/
-- and http://lua-cui.sourceforge.net/
--
-- local point = object { _init = {"x", "y"} }
--
-- local p1 = point {1, 2}
--  > p1 {x = 1, y = 2}
--

-- permute some indices of a table
local function permute (p, t)
    local u = {}
    for i, v in pairs (t) do
        if p[i] ~= nil then
            u[p[i]] = v
        else
            u[i] = v
        end
    end
    return u
end

-- make a shallow copy of a table, including any
local function clone (t)
    local u = setmetatable ({}, getmetatable (t))
    for i, v in pairs (t) do
        u[i] = v
    end
    return u
end

-- merge two tables
--
-- If there are duplicate fields, u's will be used. The metatable of
-- the returned table is that of t
--
local function merge (t, u)
    local r = clone (t)
    for i, v in pairs (u) do
        r[i] = v
    end
    return r
end

-- root object
--
-- List of fields to be initialised by the
-- constructor: assuming the default _clone, the
-- numbered values in an object constructor are
-- assigned to the fields given in _init
--
local object = { _init = {} }
setmetatable (object, object)

-- object constructor
--
-- @param initial values for fields in
--
-- @return new object
--
function object:_clone (values)
    local object = merge(self, permute(self._init, values or {}))
    return setmetatable (object, object)
end

-- local x = object {}
function object.__call (...)
  return (...)._clone (...)
end

-- return module: object
return object
