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
local platform  = require("base/platform")

-- match the tool name
function tools._match(name, toolname)

    -- match full? ok
    if name == toolname then return 100 end
 
    -- match the last word? ok
    if name:find(toolname .. "$") then return 80 end

    -- match the partial word? ok
    if name:find("%-" .. toolname) then return 60 end

    -- contains it? ok
    if name:find(toolname, 1, true) then return 30 end

    -- not matched
    return 0
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
    local file_ok = nil
    local score_maxn = 0
    local files = os.match(string.format("%s/*.lua", root))
    for _, file in ipairs(files) do

        -- the tool name
        local toolname = path.basename(file)

        -- found it?
        if toolname and toolname ~= "tools" then
            
            -- match score
            local score = tools._match(name, toolname:lower()) 

            -- ok?
            if score >= 100 then return file end
    
            -- select the file with the max score
            if score > score_maxn then
                file_ok = file
                score_maxn = score
            end
        end
    end

    -- ok?
    return file_ok
end

-- probe it's absolute path if exists from the given tool name and root directory
function tools._probe(root, name)

    -- check
    assert(root and name)

    -- make the tool path
    local toolpath = string.format("%s/%s", root, name)
    toolpath = path.translate(toolpath) 

    -- the tool exists? ok
    if toolpath and os.isfile(toolpath) then
        return toolpath
    end
end

-- find tool from the given name and directory (optional)
function tools.find(name, root)

    -- check
    assert(name)

    -- init filename
    local filepath = nil

    -- uses the basename only
    name = path.basename(name)
    assert(name)

    -- only find it from this directory if the given directory exists
    if root then return tools._find_from(root, name) end

    -- attempt to find it from the current platform directory first
    if not filepath then filepath = tools._find_from(platform.directory() .. "/tools", name) end

    -- attempt to find it from the script directory 
    if not filepath then filepath = tools._find_from(xmake._CORE_DIR .. "/tools", name) end

    -- ok?
    return filepath
end
    
-- load tool from the given name and directory (optional)
function tools.load(name, root)

    -- check
    assert(name)

    -- get it directly from cache dirst
    tools._TOOLS = tools._TOOLS or {}
    if tools._TOOLS[name] then
        return tools._TOOLS[name]
    end

    -- find the tool file path
    local toolpath = tools.find(name, root)

    -- not exists?
    if not toolpath or not os.isfile(toolpath) then
        return 
    end

    -- load script
    local script, errors = loadfile(toolpath)
    if script then
        
        -- load tool
        local tool = script()

        -- init tool 
        if tool and tool.init then
            tool:init(name)
        end

        -- save tool to the cache
        tools._TOOLS[name] = tool

        -- ok?
        return tool
    else
        utils.error(errors)
        utils.error("load %s failed!", toolpath)
        assert(false)
    end
end
    
-- get the given tool script from the given kind
function tools.get(kind)

    -- get the tool name
    local toolname = platform.tool(kind)
    if not toolname then
        utils.error("cannot get tool name for %s", kind)
        return 
    end

    -- load it
    return tools.load(toolname)
end

-- probe it's absolute path if exists from the given tool name
function tools.probe(name, dirs)

    -- check
    assert(name)

    -- attempt to run it directly first
    if os.execute(string.format("%s > %s 2>&1", name, xmake._NULDEV)) ~= 0x7f00 then
        return name
    end

    -- attempt to get it from the given directories
    if dirs then
        for _, dir in ipairs(utils.wrap(dirs)) do
            
            -- probe it
            local toolpath = tools._probe(dir, name)

            -- ok?
            if toolpath and os.execute(string.format("%s > %s 2>&1", toolpath, xmake._NULDEV)) ~= 0x7f00 then
                return toolpath
            end
        end
    end
end


-- return module: tools
return tools
