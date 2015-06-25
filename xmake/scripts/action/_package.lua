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
-- @file        _package.lua
--

-- define module: _package
local _package = _package or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local string    = require("base/string")
local platform  = require("platform/platform")
    
-- need access to the given file?
function _package.need(name)

    -- no accessors
    return false
end
 
-- configure target for the given architecture
function _package._config(arch, target)

    -- need not configure it
    if not arch then return true end

    -- done the command
    return os.execute(string.format("xmake f -P %s -f %s -a %s %s", xmake._PROJECT_DIR, xmake._PROJECT_FILE, arch, target)) == 0;
end

-- build target for the given architecture
function _package._build(arch, target)

    -- configure it first
    if not _package._config(arch, target) then return false end

    print(string.format("xmake -r -P %s %s", xmake._PROJECT_DIR, target))
    -- rebuild it
    return os.execute(string.format("xmake -r -P %s %s", xmake._PROJECT_DIR, target)) == 0;
end

-- build target for all architectures
function _package._build_all(archs, target)

    -- get the target 
    if not target or target == "all" then 
        target = ""
    end

    -- exists the given architectures?
    if archs then
    
        -- split all architectures
        archs = archs:split(",")
        if not archs then return false end

        -- build for all architectures
        for _, arch in ipairs(archs) do
            if not _package._build(arch:trim(), target) then return false end
        end

    -- build for single architecture
    elseif not _package._build(nil, target) then return false end

    -- ok
    return true
end

-- done 
function _package.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- trace
    print("package: ...")

    -- build the given target first for all architectures
    if not _package._build_all(options.archs, options.target) then
        -- errors
        utils.error("build %s failed!", utils.ifelse(options.target, options.target, "all"))
        return false
    end
 
    -- trace
    print("package: ok!")

    -- ok
    return true
end

-- the menu
function _package.menu()

    return {
                -- xmake p
                shortname = 'p'

                -- usage
            ,   usage = "xmake package|p [options] [target]"

                -- description
            ,   description = "Package target."

                -- options
            ,   options = 
                {
                    {'a', "archs",      "kv", nil,          "Package multiple given architectures."                             
                                                          , "    .e.g --archs=\"armv7, arm64\" or -a i386"
                                                          , ""
                                                          , function () 
                                                              local descriptions = {}
                                                              local plats = platform.plats()
                                                              if plats then
                                                                  for i, plat in ipairs(plats) do
                                                                      descriptions[i] = "    - " .. plat .. ":"
                                                                      local archs = platform.archs(plat)
                                                                      if archs then
                                                                          for _, arch in ipairs(archs) do
                                                                              descriptions[i] = descriptions[i] .. " " .. arch
                                                                          end
                                                                      end
                                                                  end
                                                              end
                                                              return descriptions
                                                            end                                                             }

                ,   {}
                ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
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
                ,   {nil, "target",     "v",  "all",        "Package a given target"                                        }   
                }
            }
end

-- return module: _package
return _package
