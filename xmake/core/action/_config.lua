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
-- @file        _config.lua
--

-- define module: _config
local _config = _config or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local makefile  = require("base/makefile")
local platform  = require("base/platform")

-- need access to the given file?
function _config.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { config = true, global = true, project = true, platform = true }

    -- need it?
    return accessors[name]
end

-- done 
function _config.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check target
    if not project.checktarget(options.target) then
        return false
    end

    -- trace
    print("configure ...")

    -- save the configure
    if not config.save() then
        -- error
        utils.error("save configure failed!")
        return false
    end

    -- make the configure file for the given target
    if not project.makeconf(options.target) then
        -- error
        utils.error("make configure failed!")
        return false
    end

    -- make makefile
    if not makefile.make() then
        -- error
        utils.error("make makefile failed!")
        return false
    end

    -- dump configure
    config.dump()

    -- trace
    print("configure ok!")

    -- ok
    return true
end

-- the menu
function _config.menu()

    return {
                -- xmake f
                shortname = 'f'

                -- usage
            ,   usage = "xmake config|f [options] [target]"

                -- description
            ,   description = "Configure the project."

                -- options
            ,   options = 
                {
                    {'c', "clean",      "k", nil,           "Clean the cached configure and configure all again."           }

                ,   {}
                ,   {'p', "plat",       "kv", xmake._HOST,  "Compile for the given platform."                               
                                                          , function () 
                                                                local descriptions = {}
                                                                local plats = platform.plats()
                                                                if plats then
                                                                    for i, plat in ipairs(plats) do
                                                                        descriptions[i] = "    - " .. plat
                                                                    end
                                                                end
                                                                return descriptions
                                                            end                                                             }
                ,   {'a', "arch",       "kv", "auto",       "Compile for the given architecture."                               
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
                ,   {'m', "mode",       "kv", "release",    "Compile for the given mode." 
                                                          , "    - debug"
                                                          , "    - release"
                                                          , "    - profile"                                                 }
                ,   {'k', "kind",       "kv", "static",     "Compile for the given target kind." 
                                                          , "    - static"
                                                          , "    - shared"
                                                          , "    - binary"                                                 }
                ,   {nil, "host",       "kv", xmake._HOST,  "The current host environment."                                 }

                    -- the options for project
                ,   function () return project.menu() end

                ,   {}
                ,   {nil, "make",       "kv", "auto",     "Set the make path."                                              }
                ,   {nil, "ccache",     "kv", "auto",     "Enable or disable the c/c++ compiler cache."                     }

                ,   {}
                ,   {nil, "cross",      "kv", nil,          "The cross toolchains prefix"   
                                                          , ".e.g"
                                                          , "    - i386-mingw32-"
                                                          , "    - arm-linux-androideabi-"                                  }
                ,   {nil, "toolchains", "kv", nil,          "The cross toolchains directory"                                }

                ,   {}
                ,   {nil, "cc",         "kv", nil,          "The C Compiler"                                                }
                ,   {nil, "cxx",        "kv", nil,          "The C++ Compiler"                                              }
                ,   {nil, "cflags",     "kv", nil,          "The C Compiler Flags"                                          }
                ,   {nil, "cxflags",    "kv", nil,          "The C/C++ compiler Flags"                                      }
                ,   {nil, "cxxflags",   "kv", nil,          "The C++ Compiler Flags"                                        }

                ,   {}
                ,   {nil, "as",         "kv", nil,          "The Assembler"                                                 }
                ,   {nil, "asflags",    "kv", nil,          "The Assembler Flags"                                           }
               
                ,   {}
                ,   {nil, "sc",         "kv", nil,          "The Swift Compiler"                                            }
                ,   {nil, "scflags",    "kv", nil,          "The Swift Compiler Flags"                                      }

                ,   {}
                ,   {nil, "ld",         "kv", nil,          "The Linker"                                                    }
                ,   {nil, "ldflags",    "kv", nil,          "The Binary Linker Flags"                                       }

                ,   {}
                ,   {nil, "ar",         "kv", nil,          "The Static Library Linker"                                     }
                ,   {nil, "arflags",    "kv", nil,          "The Static Library Linker Flags"                               }

                ,   {}
                ,   {nil, "sh",         "kv", nil,          "The Shared Library Linker"                                     }
                ,   {nil, "shflags",    "kv", nil,          "The Shared Library Linker Flags"                               }

                    -- the options for all platforms
                ,   function () return platform.menu("config") end

                ,   {}
                ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {'o', "buildir",    "kv", "build",      "Set the build directory."                                      }


                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Configure for the given target."                               }
                }
            }
end

-- return module: _config
return _config
