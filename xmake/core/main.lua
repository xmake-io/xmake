--!The Make-like Build Utility based on Lua
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
local deprecated    = require("base/deprecated")
local task          = require("project/task")
local history       = require("project/history")

-- init the option menu
local menu =
{
    -- title
    title = xmake._VERSION .. ", The Make-like Build Utility based on Lua"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}\nCopyright (C) 2005-2015 Mike Pall, ${underline}luajit.org${clear}"

    -- the tasks: xmake [task]
,   task.menu

}

-- done help
function main._help()

    -- done help
    if option.get("help") then
    
        -- print menu
        option.show_menu(option.taskname())

        -- ok
        return true

    -- done version
    elseif option.get("version") then

        -- print title
        if menu.title then
            utils.cprint(menu.title)
        end

        -- print copyright
        if menu.copyright then
            utils.cprint(menu.copyright)
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
    local projectfile = option.find(xmake._ARGV, "file", "F") or xmake._PROJECT_FILE
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
    if not option.init(menu) then 
        return -1
    end

    -- save command lines to history
    history.save("cmdlines", option.cmdline())

    -- run help?
    if main._help() then
        return 1
    end

    -- run task    
    local ok, errors = task.run(option.taskname() or "build")
    if not ok then
        utils.error(errors)
        return -1
    end

    -- dump deprecated entries
    deprecated.dump()

    -- stop profiling
--    profiler:stop()

    -- ok
    return 0
end

-- return module: main
return main
