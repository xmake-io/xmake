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

-- define module
local sandbox_coroutine = sandbox_coroutine or {}

-- load modules
local option    = require("base/option")
local raise     = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_coroutine.create    = coroutine.create
sandbox_coroutine.wrap      = coroutine.wrap
sandbox_coroutine.yield     = coroutine.yield
sandbox_coroutine.status    = coroutine.status
sandbox_coroutine.running   = coroutine.running

-- resume coroutine
function sandbox_coroutine.resume(co, ...)

    -- resume it
    local ok, results = coroutine.resume(co, ...)
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

        -- raise it
        raise(errors)
    end

    -- ok
    return results
end

-- load module
return sandbox_coroutine

