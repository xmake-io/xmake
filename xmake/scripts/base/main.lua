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
-- @file        main.lua
--

-- define module: main
local main = main or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local config        = require("base/config")
local global        = require("base/global")
local project       = require("base/project")
local action        = require("action/action")
local platform      = require("platform/platform")

-- init the option menu
local menu =
{
    -- title
    title = xmake._VERSION .. ", The Automatic Cross-platform Build Tool"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, tboox.org\nCopyright (C) 2005-2014 Mike Pall, luajit.org"

    -- build project: xmake
,   main = 
    {
        -- usage
        usage = "xmake [action] [options] [target]"

        -- description
    ,   description = "Build the project if no given action."

        -- actions
    ,   actions = action.list

        -- options
    ,   options = 
        {
            {'b', "build",      "k",  nil,          "Build project. This is default building mode and optional."    }
        ,   {'u', "update",     "k",  nil,          "Only relink and update the binary files."                      }
        ,   {'r', "rebuild",    "k",  nil,          "Rebuild the project."                                          }

        ,   {}
        ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
        ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                  , "Search priority:"
                                                  , "    1. The Given Command Argument"
                                                  , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                  , "    3. The Current Directory"                                  }


        ,   {}
        ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }

        ,   {}
        ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
        }
    }

    -- the actions: xmake [action]
,   action.menu

}

-- prepare global
function main._init_global()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- load global configure
    global.load()

    -- xmake global?
    if options._ACTION == "global" then

        -- probe the global platform configure 
        platform.probe(true)

        -- clear up the global configure
        global.clearup()
    end

    -- ok
    return true
end

-- init project
function main._init_project()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check the project file
    if not os.isfile(xmake._PROJECT_FILE) then
        return string.format("not found the project file: %s", xmake._PROJECT_FILE)
    end

    -- init the build directory
    if options.buildir and path.is_absolute(options.buildir) then
        options.buildir = path.relative(options.buildir, xmake._PROJECT_DIR)
    end

    -- load xmake.xconf file first
    local errors = config.load()
    if errors then return errors end

    -- xmake config or marked as "reconfig"?
    if options._ACTION == "config" or config._RECONFIG then

        -- probe the current platform 
        platform.probe(false)

    end

    -- merge the default options
    for k, v in pairs(options._DEFAULTS) do
        if nil == options[k] then options[k] = v end
    end

    -- make the current platform configure
    if not platform.make() then
        return string.format("make platform configure: %s failed!", config.get("plat"))
    end

    -- xmake config or marked as "reconfig"?
    if options._ACTION == "config" or config._RECONFIG then

        -- probe the current project 
        project.probe()

        -- clear up the configure
        config.clearup()

    end

    -- load the project 
    return project.load()
end

-- done help
function main._done_help()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- done help
    if options.help then
    
        -- print menu
        option.print_menu(options._ACTION)

        -- ok
        return true

    -- done version
    elseif options.version then

        -- print title
        if option._MENU.title then
            print(option._MENU.title)
        end

        -- print copyright
        if option._MENU.copyright then
            print(option._MENU.copyright)
        end

        -- ok
        return true
    end
end

-- done option
function main._done_option()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- done help?
    if main._done_help() then
        return true
    end

    -- done lua?
    if options._ACTION == "lua" then
        return action.done("lua")
    end

    -- init global 
    main._init_global()

    -- done global?
    if options._ACTION == "global" then
        return action.done("global")
    end

    -- init project
    local errors = main._init_project()
    if errors then
        -- error
        utils.error(errors)
        return false
    end
 
    -- reconfig it first if marked as "reconfig"
    if config._RECONFIG and not action.done("config") then
        -- error
        utils.error("reconfig failed for the changed host!")
        return false
    end

    -- done action    
    return action.done(options._ACTION or "build")
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

    -- enter the project directory
    if not os.cd(xmake._PROJECT_DIR) then
        -- error
        utils.error("not found project: %s!", xmake._PROJECT_DIR)
        return false
    end
end

-- the main function
function main.done()

    -- init 
    main._init()

    -- init option 
    if not option.init(xmake._ARGV, menu) then 
        return -1
    end

    -- done option
    if not main._done_option() then 
        return -1
    end

    -- ok
    return 0
end

-- return module: main
return main
