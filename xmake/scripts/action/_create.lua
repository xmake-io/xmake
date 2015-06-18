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
-- @file        _create.lua
--

-- define module: _create
local _create = _create or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("platform/platform")
    
-- done the given config
function _create.done()

    -- TODO
    print("not implement!")
 
    -- ok
    return true
end

-- the menu
function _create.menu()

    return {
                -- xmake p
                shortname = 'p'

                -- usage
            ,   usage = "xmake create|p [options] [target]"

                -- description
            ,   description = "Create a new project."

                -- options
            ,   options = 
                {
                    {'n', "name",       "kv", nil,          "The project name."                                             }
                ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {'l', "language",   "kv", "c",          "The project language"
                                                          , "    - c"
                                                          , "    - c++"
                                                          , "    - objc"
                                                          , "    - objc++"                                                  }
                ,   {'t', "type",       "kv", "1",          "The project type"
                                                          , "    1. The Console Program"
                                                          , "    2. The Console Program with tbox"
                                                          , "    3. The Static Library"
                                                          , "    4. The Static Library with tbox"
                                                          , "    5. The Shared Library"                                         
                                                          , "    6. The Shared Library with tbox"                           }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  nil,          "Create the given target"                     
                                                          , "Uses the project name as target if not exists."                }
                }
            }
end

-- return module: _create
return _create
