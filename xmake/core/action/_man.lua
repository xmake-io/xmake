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
-- @file        _man.lua
--

-- define module: _man
local _man = _man or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("base/platform")
    
-- need access to the given file?
function _man.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { config = true, global = true, project = true }

    -- need it?
    return accessors[name]
end

-- done 
function _man.done()

    -- TODO
    print("not implement!")
 
    -- ok
    return true
end

-- the menu
function _man.menu()

    return {
                -- xmake m
                shortname = 'm'

                -- usage
            ,   usage = "xmake man|m [options] [target]"

                -- description
            ,   description = "Create a project man."

                -- options
            ,   options = 
                {
                    {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Create man for the given target"                               }   
                }
            }
end

-- return module: _man
return _man
