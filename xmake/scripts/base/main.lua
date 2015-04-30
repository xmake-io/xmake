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
    {'p', "project",    "Change to the given prject directory before doing anything."   }
,   {'f', "file",       "Read FILE as a xmake.lua file."                                }
,   {'d', "debug",      "Print lots of debugging information."                          }
,   {'v', "version",    "Print the version number and exit."                            }
,   {'h', "help",       "Print this help message and exit."                             }
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
