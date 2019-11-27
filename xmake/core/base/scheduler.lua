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
-- @file        scheduler.lua
--

-- define module: scheduler
local scheduler = scheduler or {}

-- load modules
local table     = require("base/table")
local option    = require("base/option")
local string    = require("base/string")
local coroutine = require("base/coroutine")

-- TODO
-- the socket loop coroutine
function scheduler:_co_loop_socket()
    print("socket loop")
end

-- TODO
-- the process loop coroutine
function scheduler:_co_loop_process()
    print("process loop")
end

-- get all ready coroutines
-- 
-- ready: ready -> ready -> .. -> running -> .. -> ready -> ..->
--         |                                                    |
--          ---------------------------<------------------------
--
function scheduler:_coroutines_ready()
    local coroutines_ready = self._COROUTINES_READY
    if not coroutines_ready then
        coroutines_ready = {}
        self._COROUTINES_READY = coroutines_ready
    end
    return coroutines_ready
end

-- run new coroutine function, it will insert to the pending queue
function scheduler:run(func, ...)
    local argv = table.pack(...)
    local co = coroutine.create(function () return func(table.unpack(argv)) end)
    if not co then
        return false, "create coroutine failed!"
    end
    table.insert(self:_coroutines_ready(), co)
    return true
end

-- TODO
-- run loop, schedule coroutine with socket/io and sub-processes
function scheduler:runloop(opt)

    -- run loop
    local coroutines_ready = self:_coroutines_ready()
    while #coroutines_ready > 0 do

        -- get the first ready coroutine
        local co_ready = coroutines_ready[1]

        -- switch to this coroutine
        local ok, result_or_errors = coroutine.resume(co_ready)
        if not ok then
            return false, result_or_errors
        end
           
        -- this coroutine has been finished? we remove it from the ready queue
        if coroutine.status(co_ready) == "dead" then
            table.remove(coroutines_ready, 1)
        end
    end
    return true
end

-- return module: scheduler
return scheduler
