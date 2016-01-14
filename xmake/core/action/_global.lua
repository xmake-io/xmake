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
-- @file        _global.lua
--

-- define module: _global
local _global = _global or {}

-- load modules
local utils     = require("base/utils")
local global    = require("base/global")
local platform  = require("base/platform")

-- need access to the given file?
function _global.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { global = true }

    -- need it?
    return accessors[name]
end

-- done 
function _global.done()

    -- probe the global platform configure 
    if not platform.probe(true) then
        return false
    end

    -- clear up the global configure
    global.clearup()
    
    -- save the global configure
    if not global.save() then
        -- error
        utils.error("save configure failed!")
        return false
    end

    -- dump global
    global.dump()

    -- ok
    print("configure ok!")
    return true
end

-- the menu
function _global.menu()

    return {
                -- xmake g
                shortname = 'g'

                -- usage
            ,   usage = "xmake global|g [options] [target]"

                -- description
            ,   description = "Configure the global options for xmake."

                -- options
            ,   options = 
                {
                    {'c', "clean",      "k",    nil,            "Clean the cached configure and configure all again."       }
                ,   {nil, "make",       "kv",   "auto",         "Set the make path."                                        }
                ,   {nil, "ccache",     "kv",   "auto",         "Enable or disable the c/c++ compiler cache." 
                                                             ,  "    --ccache=[y|n]"                                        }

                ,   {}
                    -- the options for all platforms
                ,   function () return platform.menu("global") end

                ,   {}
                ,   {'v', "verbose",    "k",    nil,            "Print lots of verbose information."                        }
                ,   {nil, "version",    "k",    nil,            "Print the version number and exit."                        }
                ,   {'h', "help",       "k",    nil,            "Print this help message and exit."                         }
                }
            }
end

-- return module: _global
return _global
