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
local main = {}

-- load modules
local utils     = require("base/utils")
local option    = require("base/option")

-- init the option menu
option._MENU =
{
    -- title
    title = "XMake" .. xmake._VERSION .. ", The Automatic Cross-platform Build Tool"

    -- copyright
,   copyright =
    [[
        Copyright (C) 2015-2016 Ruki Wang, tboox.org
        Copyright (C) 2005-2014 Mike Pall, luajit.org
    ]]

    -- build project: xmake
,   main = 
    {
        -- usage
        usage = "xmake [action] [options] ..."

        -- options
    ,   options = 
        {
            {'p', "project",    "Change to the given project directory."                        }
        ,   {'f', "file",       "Read a given xmake.lua file."                                  }
        ,   {'-', "verbose",    "Print lots of verbose information."                            }
        ,   {'v', "version",    "Print the version number and exit."                            }
        ,   {'h', "help",       "Print this help message and exit."                             }
        }
    }

    -- create project: xmake create
,   create =
    {
        -- xmake p
        shortname = 'p'

        -- usage
    ,   usage = "xmake create|p [options] ..."

        -- description
    ,   description = "Create a new project."

        -- options
    ,   options = 
        {
        }
    }

    -- config project: xmake config
,   config = 
    {
        -- xmake f
        shortname = 'f'

        -- usage
    ,   usage = "xmake config|f [options] ..."

        -- description
    ,   description = "Configure the project."

        -- options
    ,   options = 
        {
        }
    }

    -- install project: xmake install
,   install =
    {
        -- xmake i
        shortname = 'i'

        -- usage
    ,   usage = "xmake install|i [options] ..."

        -- description
    ,   description = "Package and install the project binary files."

        -- options
    ,   options = 
        {
        }
    }

    -- clean project: xmake clean
,   clean =
    {
        -- xmake c
        shortname = 'c'

        -- usage
    ,   usage = "xmake clean|c [options] ..."

        -- description
    ,   description = "Clean the project binary and temporary files."

        -- options
    ,   options = 
        {
        }
    }
}

-- the main function
function main.done()

    -- done option first
    if not option.done(xmake._ARGV) then 

        -- print the help option
        option.help()

        -- failed
        return -1
    end
    
    -- ok
    return 0
end

-- return module: main
return main
