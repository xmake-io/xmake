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
-- @file        coroutine.lua
--

-- define module: coroutine
local coroutine = coroutine or {}

-- load modules
local utils     = require("base/utils")
local option    = require("base/option")
local string    = require("base/string")

-- save original interfaces
coroutine._resume  = coroutine._resume or coroutine.resume

-- resume coroutine
function coroutine.resume(co, ...)

    -- resume it
    local ok, results = coroutine._resume(co, ...)
    if not ok then

        -- get errors
        local errors = results
        if option.get("diagnosis") then
            errors = debug.traceback(co, results)
        elseif type(results) == "string" then
            -- remove the prefix info
            local _, pos = results:find(":%d+: ")
            if pos then
                errors = results:sub(pos + 1)
            end
        end

        -- failed
        return false, errors
    end

    -- ok
    return true, results
end

-- return module: coroutine
return coroutine
