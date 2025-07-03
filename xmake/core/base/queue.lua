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
-- @file        queue.lua
--

-- load modules
local object = require("base/object")

-- define module
local queue = queue or object {_init = {"_first", "_last"}} {1, 0}

-- clear queue
function queue:clear()
    self._first = 1
    self._last = 0
end

-- push item to queue
function queue:push(item)
    local last = self._last + 1
    self._last = last
    self[last] = item
end

-- pop item from queue
function queue:pop()
    local first = self._first
    if first > self._last then
        return nil
    end

    local value = self[first]
    self[first] = nil
    self._first = first + 1
    return value
end

-- get queue size
function queue:size()
    return self._last - self._first + 1
end

-- is queue empty?
function queue:empty()
    return self._first > self._last
end

-- peek the first item of queue
function queue:first()
    if self._first > self._last then
        return nil
    end
    return self[self._first]
end

-- peek the last item of queue
function queue:last()
    if self._first > self._last then
        return nil
    end
    return self[self._last]
end

-- iterator for all items (forward)
--
-- e.g.
--
-- for item in queue:items() do
--     print(item)
-- end
--
function queue:items()
    local index = self._first - 1
    local last = self._last
    return function()
        index = index + 1
        if index <= last then
            return self[index]
        end
    end
end

-- iterator for all items (reverse)
function queue:ritems()
    local index = self._last + 1
    local first = self._first
    return function()
        index = index - 1
        if index >= first then
            return self[index]
        end
    end
end

-- clone queue
function queue:clone()
    local q = queue.new()
    for i = self._first, self._last do
        q:push(self[i])
    end
    return q
end

-- new queue
function queue.new()
    return queue()
end

-- return module: queue
return queue
