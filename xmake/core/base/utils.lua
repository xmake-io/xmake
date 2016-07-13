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
local colors = require("base/colors")

-- print format string with newline
function utils.print(format, ...)

    -- check
    assert(format)

    -- trace
    print(string.format(format, ...))
end

-- print format string without newline
function utils.printf(format, ...)

    -- check
    assert(format)

    -- trace
    io.write(string.format(format, ...))
end

-- print format string and colors with newline
function utils.cprint(format, ...)

    -- check
    assert(format)

    -- trace
    print(colors(string.format(format, ...)))
end

-- print format string and colors without newline
function utils.cprintf(format, ...)

    -- check
    assert(format)

    -- trace
    io.write(colors(string.format(format, ...)))
end

-- the verbose function
function utils.verbose(format, ...)

    -- enable verbose?
    if option.get("verbose") and format ~= nil then
        
        -- trace
        print(string.format(format, ...))
    end
end

-- the error function
function utils.error(format, ...)

    -- trace
    if format ~= nil then
        utils.cprint("${bright red}error: ${default red}" .. string.format(format, ...))
    end
end

-- the warning function
function utils.warning(format, ...)

    -- check
    assert(format)

    -- format message
    local msg = "${bright yellow}warning: ${default yellow}" .. string.format(format, ...)

    -- init warnings
    utils._WARNINGS = utils._WARNINGS or {}
    local warnings = utils._WARNINGS

    -- trace only once
    if not warnings[msg] then
        utils.cprint(msg)
        warnings[msg] = true
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
