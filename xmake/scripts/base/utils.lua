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
-- @file        utils.lua
--

-- define module: utils
local utils = {}

-- the printf function
function utils.printf(msg, ...)
    print(string.format(msg, ...))
end

-- the verbose function
function utils.verbose(msg, ...)
    if xmake._OPTIONS.verbose then
        print(string.format(msg, ...))
    end
end

-- the error function
function utils.error(msg, ...)
    print("error: " .. string.format(msg, ...))
end

-- the warning function
function utils.warning(msg, ...)
    print("warning: " .. string.format(msg, ...))
end

-- ifelse, a? b : c
function utils.ifelse(a, b, c)
    if a then return b else return c end
end

-- return module: utils
return utils
