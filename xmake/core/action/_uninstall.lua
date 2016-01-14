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
-- @file        _uninstall.lua
--

-- define module: _uninstall
local _uninstall = _uninstall or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local global    = require("base/global")
local install   = require("base/install")
local uninstall = require("base/uninstall")
local package   = require("base/package")
local project   = require("base/project")
local platform  = require("base/platform")
     
-- need access to the given file?
function _uninstall.need(name)

    -- no accessors
    return false
end

-- package target
function _uninstall._package(target_name)

    -- get the target name
    if not target_name or target_name == "all" then 
        target_name = ""
    end

    -- package it
    if os.execute(string.format("xmake p -P %s -f %s %s", xmake._PROJECT_DIR, xmake._PROJECT_FILE, target_name)) ~= 0 then 
        return false 
    end

    -- ok
    return true
end

 
-- done 
function _uninstall.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- trace
    print("uninstall: ...")

    -- load the global configure first
    global.load()

    -- enter the project directory
    if not os.cd(xmake._PROJECT_DIR) then
        -- errors
        utils.error("not found project: %s!", xmake._PROJECT_DIR)
        return false
    end

    -- load the install configure
    local configs, errors = install.load()
    if not configs then
        -- errors
        utils.error(errors)
        return false
    end

    -- reload configure
    local errors = config.reload()
    if errors then
        -- error
        utils.error(errors)
        return false
    end

    -- make the platform configure
    if not platform.make() then
        utils.error("make platform configure: %s failed!", config.get("plat"))
        return false
    end

    -- reload project
    local errors = project.reload()
    if errors then
        -- error
        utils.error(errors)
        return false
    end

    -- done uninstall 
    if not uninstall.done(configs) then
        -- errors
        utils.error("uninstall: failed!")
        return false
    end

    -- trace
    print("uninstall: ok!")

    -- ok
    return true
end

-- the menu
function _uninstall.menu()

    return {
                -- xmake u
                shortname = 'u'

                -- usage
            ,   usage = "xmake uninstall|u [options] [target]"

                -- description
            ,   description = "Uninstall the project binary files."

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
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Install the given target."                                     }
                }
        }
end

-- return module: _uninstall
return _uninstall
