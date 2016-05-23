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
-- @file        xmake.lua
--

-- define task
task("run")

    -- set category
    set_task_category("action")

    -- on run
    on_task_run("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake run|r [options] [target] [arguments]"

                    -- description
                ,   description = "Run the project target."

                    -- xmake r
                ,   shortname = 'r'
 
                    -- options
                ,   options = 
                    {
                        {'d', "debug",      "k",  nil,          "Run and debug the given target."                               }
                    ,   {nil, "debugger",   "kv", "auto",       "Set the debugger path."                                        }

                    ,   {}
                    ,   {nil, "target",     "v",  nil,          "Run the given target."                                         }      
                    ,   {nil, "arguments",  "vs",  nil,         "The target arguments"                                          }
                    }
                })



