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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        timer.lua
--

-- load modules
local heap   = require("base/heap")
local object = require("base/object")

-- define module: timer
local timer  = timer or object()

-- tostring(timer)
function timer:__tostring()
    return string.format("<timer: %s>", self:name())
end

-- get all timer tasks
function timer:_tasks()
    return self._TASKS
end

-- post timer task after delay and will be auto-remove it after be expired
function timer:post(func, delay, opt)
    return self:post_at(func, os.mclock() + delay, delay, opt)
end

-- post timer task at the absolute time and will be auto-remove it after be expired
--
-- we can mark the returned task as canceled to cancel the pending task, e.g. task.cancel = true
--
function timer:post_at(func, when, period, opt)
    opt = opt or {}
    local task = {when = when, func = func, period = period, continuous = opt.continuous, cancel = false}
    self:_tasks():push(task)
    return task
end

-- post timer task after the relative time and will be auto-remove it after be expired
function timer:post_after(func, after, period, opt)
    return self:post_at(func, os.mclock() + after, period, opt)
end

-- get the delay of next task
function timer:delay()
    local delay = nil
    local tasks = self:_tasks()
    if tasks:length() > 0 then
        local task = tasks:peek()
        if task then
            local now = os.mclock()
            delay = task.when > now and task.when - now or 0
        end
    end
    return delay
end

-- run the timer next loop
function timer:next()
    local tasks = self:_tasks()
    while tasks:length() > 0 do
        local triggered = false
        local task = tasks:peek()
        if task then
            -- timeout or canceled?
            if task.cancel or task.when <= os.mclock() then
                tasks:pop()
                if task.continuous and not task.cancel then
                    task.when = os.mclock() + task.period
                    tasks:push(task)
                end
                -- run timer task
                if task.func then
                    local ok, errors = task.func(task.cancel)
                    if not ok then
                        return false, errors
                    end
                    triggered = true
                end
            end
        end
        if not triggered then
            break
        end
    end
    return true
end

-- kill all timer tasks
function timer:kill()
    local tasks = self:_tasks()
    while tasks:length() > 0 do
        local task = tasks:peek()
        if task then
            tasks:pop()
            if task.func then
                -- cancel it
                task.func(true)
            end
        end
    end
end

-- get timer name
function timer:name()
    return self._NAME
end

-- init timer
function timer:init(name)
    self._NAME  = name or "none"
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
