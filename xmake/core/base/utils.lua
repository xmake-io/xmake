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
-- @file        utils.lua
--

-- define module
local utils = utils or {}

-- load modules
local option = require("base/option")

-- the printf function
function utils.printf(msg, ...)

    -- check
    assert(msg)

    -- trace
    print(string.format(msg, ...))
end

-- the verbose function
function utils.verbose(msg, ...)

    if option.get("verbose") and msg ~= nil then
        
        -- trace
        print(string.format(msg, ...))
    end
end

-- the error function
function utils.error(msg, ...)

    -- trace
    if msg ~= nil then
        print("error: " .. string.format(msg, ...))
    end
end

-- the warning function
function utils.warning(msg, ...)

    -- check
    assert(msg)

    -- format message
    msg = "warning: " .. string.format(msg, ...)

    -- init warnings
    utils._WARNINGS = utils._WARNINGS or {}
    local warnings = utils._WARNINGS

    -- the cached file path
    local cachedpath = path.translate(xmake._PROJECT_DIR .. "/.xmake/warnings")

    -- load warnings from the cached file
    local cachedfile = io.open(cachedpath, "r")
    if cachedfile then
        for line in cachedfile:lines() do
            warnings[line] = true
        end
    end

    -- trace only once
    if not warnings[msg] then
        print(msg)
        warnings[msg] = true
    end

    -- cache warnings
    cachedfile = io.open(cachedpath, "w")
    if cachedfile then
        for line, _ in pairs(warnings) do
            cachedfile:write(line .. "\n")
        end
        cachedfile:close()
    end
end

-- ifelse, a? b : c
function utils.ifelse(a, b, c)
    if a then return b else return c end
end

-- call functions 
function utils.call(funcs, pred, ...)

    -- check
    assert(funcs)

    -- call all
    for _, func in ipairs(table.wrap(funcs)) do
        
        -- check
        assert(type(func) == "function")

        -- call it
        local result = func(...)

        -- exists predicate?
        if pred and type(pred) == "function" then
            if not pred(name, result) then return false end
        -- failed?
        elseif not result then return false end
    end

    -- ok
    return true
end

-- return module
return utils
