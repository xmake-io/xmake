--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
        if option.get("backtrace") then
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

