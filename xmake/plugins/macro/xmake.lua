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
-- @file        macro.lua
--

-- define task
task("macro")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu({
                    -- usage
                    usage = "xmake macro|m [options] [name] [arguments]"

                    -- description
                ,   description = "Run the given macro."

                    -- xmake m
                ,   shortname = 'm'

                    -- options
                ,   options = 
                    {
                        {'b', "begin",      "k",  nil,  "Start to record macro."                          
                                                    ,   ".e.g"
                                                    ,   "Record macro with name: test"
                                                    ,   "    xmake macro --begin"                   
                                                    ,   "    xmake config --plat=macosx"
                                                    ,   "    xmake clean"
                                                    ,   "    xmake -r"
                                                    ,   "    xmake package"
                                                    ,   "    xmake macro --end test"                    }
                    ,   {'e', "end",        "k",  nil,  "Stop to record macro."                         }
                    ,   {}
                    ,   {nil, "show",       "k",  nil,  "Show the content of the given macro."          }
                    ,   {'l', "list",       "k",  nil,  "List all macros."                              }
                    ,   {'d', "delete",     "k",  nil,  "Delete the given macro."                       }
                    ,   {'c', "clear",      "k",  nil,  "Clear the all macros."                         }
                    ,   {}
                    ,   {nil, "import",     "kv", nil,  "Import the given macro file or directory."                   
                                                    ,   ".e.g"
                                                    ,   "    xmake macro --import=/xxx/macro.lua test"
                                                    ,   "    xmake macro --import=/xxx/macrodir"        }
                    ,   {nil, "export",     "kv", nil,  "Export the given macro to file or directory."
                                                    ,   ".e.g"
                                                    ,   "    xmake macro --export=/xxx/macro.lua test"  
                                                    ,   "    xmake macro --export=/xxx/macrodir"        }
                    ,   {}
                    ,   {nil, "name",       "v",  ".",  "Set the macro name."
                                                    ,   ".e.g"
                                                    ,   "   Run the given macro:     xmake macro test"        
                                                    ,   "   Run the anonymous macro: xmake macro ."     }
                    ,   {nil, "arguments",  "vs", nil,  "Set the macro arguments."                      }
                    }
                })
