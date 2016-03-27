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
-- @file        main.lua
--

-- define module: main
local main = main or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local profiler      = require("base/profiler")
local task          = require("project/task")

-- init the option menu
local menu =
{
    -- title
    title = xmake._VERSION .. ", The Automatic Cross-platform Build Tool"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, tboox.org\nCopyright (C) 2005-2014 Mike Pall, luajit.org"

    -- the tasks: xmake [task]
,   task.menu

}

-- done help
function main._help()

    -- done help
    if option.get("help") then
    
        -- print menu
        option.print_menu(option.task())

        -- ok
        return true

    -- done version
    elseif option.get("version") then

        -- print title
        if menu.title then
            print(menu.title)
        end

        -- print copyright
        if menu.copyright then
            print(menu.copyright)
        end

        -- ok
        return true
    end
end

-- the init function for main
function main._init()

    -- init the project directory
    local projectdir = option.find(xmake._ARGV, "project", "P") or xmake._PROJECT_DIR
    if projectdir and not path.is_absolute(projectdir) then
        projectdir = path.absolute(projectdir)
    elseif projectdir then 
        projectdir = path.translate(projectdir)
    end
    xmake._PROJECT_DIR = projectdir
    assert(projectdir)

    -- init the xmake.lua file path
    local projectfile = option.find(xmake._ARGV, "file", "f") or xmake._PROJECT_FILE
    if projectfile and not path.is_absolute(projectfile) then
        projectfile = path.absolute(projectfile, projectdir)
    end
    xmake._PROJECT_FILE = projectfile
    assert(projectfile)
end

-- the main function
function main.done()

    -- start profiling
--    profiler:start()

    -- init 
    main._init()

    -- init option 
    if not option.init(xmake._ARGV, menu) then 
        return -1
    end

    -- run help?
    if main._help() then
        return 1
    end

    -- run task    
    local ok = task.run(option.task() or "build")
    if not ok then
        return -1
    end

    -- stop profiling
--    profiler:stop()

    -- ok
    return 0
end

-- return module: main
return main
