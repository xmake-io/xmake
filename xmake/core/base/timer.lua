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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        timer.lua
--

-- load modules
local heap   = require("base/heap")
local object = require("base/object")

-- define module: timer
local timer  = timer or object()

-- get all timer tasks
function timer:_tasks()
    return self._TASKS
end

-- post timer task at the absolute time and will be auto-remove it after be expired
function timer:post_at(when, period, is_repeat, task)
    -- TODO
end

-- get timer name
function timer:name()
    return self._NAME
end

-- init timer
function timer:init(name)
    self._NAME  = name
    self._TASKS = heap.valueheap {cmp = function(a, b)
        return a.when < b.when
    end}
end

-- new timer
function timer:new(name)
    self = self()
    self:init(name)
    return self
end

-- return module: timer
return timer
