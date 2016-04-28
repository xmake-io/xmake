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
task("build")

    -- set category
    set_task_category("main")

    -- on run
    on_task_run("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake [task] [options] [target]"

                    -- description
                ,   description = "Build the project if no given tasks."

                    -- options
                ,   options = 
                    {
                        {'b', "build",      "k",  nil,          "Build project. This is default building mode and optional."    }
                    ,   {'r', "rebuild",    "k",  nil,          "Rebuild the project."                                          }

                    ,   {}
                    ,   {'j', "jobs",       "kv", nil,          "Specifies the number of jobs to build simultaneously"          }
                   
                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
                    }
                })



