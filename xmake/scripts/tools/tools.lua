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
-- @file        tools.lua
--

-- define module: tools
local tools = tools or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local platform  = require("platform/platform")

-- match the tool name
function tools._match(name, toolname)

    -- match full? ok
    if name == toolname then return true end
    
    -- match the full word? ok
    if name:find("^" .. toolname .. "$") then return true end

    -- contains it? ok
    if name:find(toolname, true) then return true end

    -- not matched
    return false
end

-- find tool from the given root directory and name
function tools._find_from(root, name)

    -- attempt to get it directly first
    local filepath = string.format("%s/%s.lua", root, name)
    if os.isfile(filepath) then
        return filepath
    end

    -- make the lower name
    name = name:lower()

    -- get all tool files
    local files = os.match(string.format("%s/*.lua", root))
    for _, file in ipairs(files) do

        -- the tool name
        local toolname = path.basename(file)

        -- found it?
        if toolname and toolname ~= "tools" and tools._match(name, toolname:lower()) then
            return file
        end
    end

end

-- find tool from the given name and directory (optional)
function tools.find(name, root)

    -- check
    assert(name)

    -- init filename
    local filepath = nil

    -- only find it from this directory if the given directory exists
    if root then return tools._find_from(root, name) end

    -- attempt to find it from the current platform directory first
    if not filepath then filepath = tools._find_from(platform.directory() .. "/tools", name) end

    -- attempt to find it from the script directory 
    if not filepath then filepath = tools._find_from(xmake._SCRIPTS_DIR .. "/tools", name) end

    -- ok?
    return filepath
end
    
-- load tool from the given name and directory (optional)
function tools.load(name, root)

    -- find the tool file path
    local toolpath = tools.find(name, root)

    -- not exists?
    if not toolpath or not os.isfile(toolpath) then
        return 
    end

end
    
-- return module: tools
return tools
