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
-- @file        path.lua
--

-- define module: path
local path = path or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")

-- get the directory of the path
function path.directory(p)
    local i = p:find_last("[/\\]")
    if i then
        if i > 1 then i = i - 1 end
        return p:sub(1, i)
    else
        return "."
    end
end

-- get the filename of the path
function path.filename(p)
    local i = p:find_last("[/\\]")
    if i then
        return p:sub(i + 1)
    else
        return p
    end
end

-- get the basename of the path
function path.basename(p)
    local name = path.filename(p)
    local i = name:find_last(".", true)
    if i then
        return name:sub(1, i - 1)
    else
        return name
    end
end

-- get the file extension of the path: .xxx
function path.extension(p)

    -- check
    assert(p)

    -- get extension
    local i = p:find_last(".", true)
    if i then
        return p:sub(i)
    else
        return ""
    end
end

-- join path
function path.join(p, ...)

    -- check
    assert(p)

    -- join them
    for _, name in ipairs({...}) do
        p = p .. "/" .. name
    end

    -- translate path
    return path.translate(p)
end

-- return module: path
return path
