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
-- @file        tool.lua
--

-- define module
local tool      = tool or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local filter    = require("base/filter")
local config    = require("project/config")
local global    = require("project/global")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")

-- the directories of tools
function tool._directories(name)

    -- the kinds
    local kinds = 
    {
        cc      = "compiler"
    ,   cxx     = "compiler"
    ,   mm      = "compiler"
    ,   mxx     = "compiler"
    ,   sc      = "compiler"
    ,   ar      = "linker"
    ,   sh      = "linker"
    ,   ld      = "linker"
    }

    -- get kind sub-directory
    local subdir = kinds[name] or ""

    -- the directories
    return  {   path.join(path.join(config.directory(), "tools"), subdir)
            ,   path.join(path.join(global.directory(), "tools"), subdir)
            ,   path.join(path.join(xmake._PROGRAM_DIR, "tools"), subdir)
            }
end

-- match the tool name
function tool._match(name, toolname)

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
function tool._find(root, name)

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
        if toolname and toolname ~= "tool" then
            
            -- match score
            local score = tool._match(name, toolname:lower()) 

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

-- load the given tool from the given kind
--
-- the kinds:
-- 
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function tool.load(kind)

    -- get the shell name 
    local shellname = platform.tool(kind)
    if not shellname then
        return nil, string.format("cannot get tool for %s", kind)
    end

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[kind] then
        return tool._TOOLS[kind]
    end

    -- find the tool script path
    local toolpath = nil
    local toolname = path.basename(shellname)
    for _, dir in ipairs(tool._directories(kind)) do

        -- find this directory
        toolpath = tool._find(dir, toolname)
        if toolpath then
            break
        end

    end

    -- not exists?
    if not toolpath or not os.isfile(toolpath) then
        return nil, string.format("%s not found!", shellname)
    end

    -- load script
    local script, errors = loadfile(toolpath)
    if script then

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, nil, path.directory(toolpath))
        if not instance then
            return nil, errors
        end

        -- import the tool module
        local module, errors = instance:import()
        if not module then
            return nil, errors
        end

        -- init the tool module
        if module.init then
            module.init(shellname)
        end
    
        -- save tool to the cache
        tool._TOOLS[kind] = module

        -- ok?
        return module
    end

    -- failed
    return nil, errors
end

-- check the tool and return the absolute path if exists
function tool.check(shellname, dirs)

    -- check
    assert(shellname)

    -- FIXME: 7f00
    -- attempt to run it directly first
    if os.execute(string.format("%s > %s 2>&1", shellname, xmake._NULDEV)) ~= 0x7f00 then
        return shellname
    end

    -- attempt to get it from the given directories
    for _, dir in ipairs(table.wrap(dirs)) do
        
        -- check it
        local toolpath = path.translate(string.format("%s/%s", dir, shellname))
        if os.isfile(toolpath) and os.execute(string.format("%s > %s 2>&1", toolpath, xmake._NULDEV)) ~= 0x7f00 then
            return toolpath
        end
    end
end

-- return module
return tool
