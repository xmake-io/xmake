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
-- @file        _clean.lua
--

-- define module: _clean
local _clean = _clean or {}

-- load modules
local clean     = require("base/clean")
local config    = require("base/config")
local project   = require("base/project")
local utils     = require("base/utils")
local platform  = require("base/platform")

-- need access to the given file?
function _clean.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { global = true, config = true, project = true, platform = true }

    -- need it?
    return accessors[name]
end

-- done 
function _clean.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check target
    if not project.checktarget(options.target) then
        return false
    end

    -- clean the current target
    if not clean.remove(options.target, utils.ifelse(options.all, "all", "build")) then
        return false
    end

    -- trace
    print("clean ok!")
 
    -- ok
    return true
end

-- the menu
function _clean.menu()

    return {
                -- xmake c
                shortname = 'c'

                -- usage
            ,   usage = "xmake clean|c [options] [target]"

                -- description
            ,   description = "Remove all binary and temporary files."

                -- options
            ,   options = 
                {
                    {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {}
                ,   {'a', "all",        "k",  nil,          "Clean all auto-generated files by xmake."                      }
                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
                
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Clean for the given target."                                   }      
                }
            }
end

-- return module: _clean
return _clean
