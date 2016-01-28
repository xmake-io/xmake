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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        sandbox.lua
--

-- define module: sandbox
local sandbox = sandbox or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- traceback
function sandbox._traceback(errors)

    -- init results
    local results = ""
    if errors then
        results = errors .. "\n"
    end
    results = results .. "stack traceback:\n"

    -- make results
    local level = 2    
    while true do    

        -- get debug info
        local info = debug.getinfo(level, "Sln")

        -- end?
        if not info or (info.name and info.name == "xpcall") then
            break
        end

        -- function?
        if info.what == "C" then
            results = results .. string.format("    [C]: in function '%s'\n", info.name)
        elseif info.name then 
            results = results .. string.format("    [%s:%d]: in function '%s'\n", info.short_src, info.currentline, info.name)    
        elseif info.what == "main" then
            results = results .. string.format("    [%s:%d]: in main chunk\n", info.short_src, info.currentline)    
            break
        else
            results = results .. string.format("    [%s:%d]:\n", info.short_src, info.currentline)    
        end

        -- next
        level = level + 1    
    end    

    -- ok?
    return results
end

-- init sandbox
function sandbox.init()

    -- init an sandbox instance
    local box = {    _PUBLIC = {}
                 ,   _PRIVATE = {}}

    -- inherit the interfaces of sandbox
    for k, v in pairs(sandbox) do
        if type(v) == "function" then
            box[k] = v
        end
    end

    -- ok?
    return box
end

-- bind sandbox to script
function sandbox.bind(self, script)

    -- check
    assert(self and self._PUBLIC)

    -- this script is file? load it first
    if type(script) == "string" and os.isfile(script) then

        -- load it
        local filescript, errors = loadfile(script)
        if filescript then

            -- bind public scope
            setfenv(filescript, self._PUBLIC)

            -- get main script
            script = filescript()
            if type(script) == "table" and script.main then 
                script = script.main
            end
        else
            return false, errors
        end
    end

    -- no script?
    if script == nil then
        return false, "no script!"
    end

    -- invalid script?
    if script ~= nil and type(script) ~= "function" then
        return false, "invalid script!"
    end

    -- bind public scope
    setfenv(script, self._PUBLIC)

    -- ok
    return true
end

-- return module: sandbox
return sandbox
