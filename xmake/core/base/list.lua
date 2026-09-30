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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        list.lua
--

-- load modules
local object = require("base/object")

-- define module
local list = list or object { _init = {"_length"} } {0}

-- clear all elements
function list:clear()
    self._length = 0
    self._first  = nil
    self._last   = nil
end

-- insert item after the given item
function list:insert(t, after)
    if not after then
        return self:insert_last(t)
    end
    assert(t ~= after)
    if after._next then
        after._next._prev = t
        t._next = after._next
    else
        self._last = t
    end
    t._prev = after
    after._next = t
    self._length = self._length + 1
end

-- insert the first item in head
function list:insert_first(t)
    if self._first then
        self._first._prev = t
        t._next = self._first
        self._first = t
    else
        self._first = t
        self._last = t
    end
    self._length = self._length + 1
end

-- insert the last item in tail
function list:insert_last(t)
    if self._last then
        self._last._next = t
        t._prev = self._last
        self._last = t
    else
        self._first = t
        self._last = t
    end
    self._length = self._length + 1
end

-- remove item
function list:remove(t)
    if t._next then
        if t._prev then
            t._next._prev = t._prev
            t._prev._next = t._next
        else
            assert(t == self._first)
            t._next._prev = nil
            self._first = t._next
        end
    elseif t._prev then
        assert(t == self._last)
        t._prev._next = nil
        self._last = t._prev
    else
        assert(t == self._first and t == self._last)
        self._first = nil
        self._last = nil
    end
    t._next = nil
    t._prev = nil
    self._length = self._length - 1
    return t
end

-- remove the first item
function list:remove_first()
    if not self._first then
        return
    end
    local t = self._first
    if t._next then
        t._next._prev = nil
        self._first = t._next
        t._next = nil
    else
        self._first = nil
        self._last = nil
    end
    self._length = self._length - 1
    return t
end

-- remove last item
function list:remove_last()
    if not self._last then
        return
    end
    local t = self._last
    if t._prev then
        t._prev._next = nil
        self._last = t._prev
        t._prev = nil
    else
        self._first = nil
        self._last = nil
    end
    self._length = self._length - 1
    return t
end

-- push element to the back
--
-- @param t     the element
--
function list:push(t)
    self:insert_last(t)
end

-- pop element from the back
--
-- @return      the removed element
--
function list:pop()
    return self:remove_last()
end

-- shift element from the front
--
-- @return      the removed element
--
function list:shift()
    return self:remove_first()
end

-- unshift element to the front
--
-- @param t     the element
--
function list:unshift(t)
    self:insert_first(t)
end

-- get the first element
--
-- @return      the first element, or nil if empty
--
function list:first()
    return self._first
end

-- get the last element
--
-- @return      the last element, or nil if empty
--
function list:last()
    return self._last
end

-- get the next element after the given one
--
-- @param last  the current element
-- @return      the next element, or nil
--
function list:next(last)
    if last then
        return last._next
    else
        return self._first
    end
end

-- get the previous element before the given one
--
-- @param last  the current element
-- @return      the previous element, or nil
--
function list:prev(last)
    if last then
        return last._prev
    else
        return self._last
    end
end

-- get the list size
--
-- @return      the number of elements
--
function list:size()
    return self._length
end

-- is the list empty?
--
-- @return      true if empty
--
function list:empty()
    return self:size() == 0
end

-- get items
--
-- e.g.
--
-- for item in list:items() do
--     print(item)
-- end
--
-- iterate elements from front to back
--
-- @return      the iterator function
--
-- Stateful closure so the loop body can safely reassign the first loop
-- variable under lua 5.4+ (paired with the RDKCONST->VDKREG compile-time
-- patch in core/src/lua/xmake.lua).
function list:items()
    -- stateful closure: keep the cursor in an upvalue so the loop body
    -- can safely reassign the first loop variable (lua 5.4+ merges the
    -- for-in control slot with the first user variable).
    local item = nil
    return function ()
        item = self:next(item)
        return item
    end
end

-- iterate elements from back to front
--
-- @return      the reverse iterator function
--
-- Stateful closure; see `list:items()` for the rationale.
function list:ritems()
    local item = nil
    return function ()
        item = self:prev(item)
        return item
    end
end

-- create a new doubly-linked list
--
-- @return      the list instance
--
function list.new()
    return list()
end

-- return module: list
return list
