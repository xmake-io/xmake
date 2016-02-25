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
-- @file        lua.lua
--

-- define task
task("lua")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake lua|l [options] [script] [arguments]"

                    -- description
                ,   description = "Run the lua script."

                    -- xmake l
                ,   shortname = 'l'

                    -- options
                ,   options = 
                    {
                        {'f', "file",       "kv", nil,          "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }

                    ,   {}
                    ,   {'s', "string",     "k",  nil,          "Run the lua string script."                                    }

                    ,   {}
                    ,   {nil, "script",     "v",  nil,          "Run the given lua script."
                                                              , "    - The script name from the xmake tool directory"
                                                              , "    - The script file"
                                                              , "    - The script string"                                       }      
                    ,   {nil, "arguments",  "vs", nil,          "The script arguments"                                          }
                    }
                })



