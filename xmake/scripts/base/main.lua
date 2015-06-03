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
-- @file        main.lua
--

-- define module: main
local main = main or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local config        = require("base/config")
local global        = require("base/global")
local project       = require("base/project")
local preprocessor  = require("base/preprocessor")
local action        = require("action/action")
local platform      = require("platform/platform")

-- init the option menu
local menu =
{
    -- title
    title = xmake._VERSION .. ", The Automatic Cross-platform Build Tool"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, tboox.org\nCopyright (C) 2005-2014 Mike Pall, luajit.org"

    -- build project: xmake
,   main = 
    {
        -- usage
        usage = "xmake [action] [options] [target]"

        -- description
    ,   description = "Build the project if no given action."

    ,   -- actions
        actions = {"create", "config", "global", "install", "clean", "run", "lua"}

        -- options
    ,   options = 
        {
            {'b', "build",      "k",  nil,          "Build project. This is default building mode and optional."    }
        ,   {'u', "update",     "k",  nil,          "Only relink and update the binary files."                      }
        ,   {'r', "rebuild",    "k",  nil,          "Rebuild the project."                                          }

        ,   {}
        ,   {'f', "file",       "kv", "xmake.xproj","Read a given xmake.xproj file."                                }
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
        ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
        }
    }

    -- create project: xmake create
,   create =
    {
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
        ,   {'f', "file",       "kv", "xmake.xproj","Create a given xmake.xproj file."                              }
        ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                  , "Search priority:"
                                                  , "    1. The Given Command Argument"
                                                  , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                  , "    3. The Current Directory"                                  }
        ,   {'l', "language",   "kv", "c",          "The project language"
                                                  , "    - c"
                                                  , "    - c++"
                                                  , "    - objc"
                                                  , "    - objc++"         
                                                  , "    - lua"                                                     }
        ,   {'t', "type",       "kv", "console",    "The project type"
                                                  , "    - console"
                                                  , "    - library_static"
                                                  , "    - library_shared"
                                                  , "    - application_empty"                                       
                                                  , "    - application_singleview"                                  
                                                  , "    - game"                                                    }

        ,   {}
        ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
 
        ,   {}
        ,   {nil, "target",     "v",  nil,          "Create the given target"                     
                                                  , "Uses the project name as target if not exists."                }
        }
    }

    -- config project: xmake config
,   config = 
    {
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
        ,   {'-', "host",       "kv", xmake._HOST,  "The current host environment."                                 }

        ,   {}
        ,   {'o', "buildir",    "kv", "build",      "Set the build directory"                                       }
        ,   {'k', "packages",   "kv", "pkg",        "Set the packages directory"                                    }

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
        ,   {'f', "file",       "kv", "xmake.xproj","Read a given xmake.xproj file."                                }
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
        ,   {nil, "target",     "v",  "all",        "Configure for the given target."                               }
        }
    }

    -- config global: xmake global
,   global = 
    {
        -- xmake g
        shortname = 'g'

        -- usage
    ,   usage = "xmake global|g [options] [target]"

        -- description
    ,   description = "Configure the global options for xmake."

        -- options
    ,   options = 
        {
            {'c', "clean",      "k", nil,           "Clean the cached configure and configure all again."           }

        ,   {}
            -- the options for all platforms
        ,   function () return platform.menu("global") end

        ,   {}
        ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
        }
    }

    -- install project: xmake install
,   install =
    {
        -- xmake i
        shortname = 'i'

        -- usage
    ,   usage = "xmake install|i [options] [target]"

        -- description
    ,   description = "Package and install the project binary files."

        -- options
    ,   options = 
        {
            {'f', "file",       "kv", "xmake.xproj","Read a given xmake.xproj file."                                }
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

    -- clean project: xmake clean
,   clean =
    {
        -- xmake c
        shortname = 'c'

        -- usage
    ,   usage = "xmake clean|c [options] [target]"

        -- description
    ,   description = "Remove all binary and temporary files."

        -- options
    ,   options = 
        {
            {'f', "file",       "kv", "xmake.xproj","Read a given xmake.xproj file."                                }
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
        ,   {nil, "target",     "v",  "all",        "Clean for the given target."                                   }      
        }
    }

    -- run target: xmake run
,   run =
    {
        -- xmake r
        shortname = 'r'

        -- usage
    ,   usage = "xmake run|r [options] [target] [arguments]"

        -- description
    ,   description = "Run the project target."

        -- options
    ,   options = 
        {
            {'d', "debug",      "k",  nil,          "Run and debug the given target."                               }
        ,   {nil, "debugger",   "kv", "auto",       "Set the debugger path."                                        }

        ,   {}
        ,   {'f', "file",       "kv", "xmake.xproj","Read a given xmake.xproj file."                                }
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
        ,   {nil, "target",     "v",  nil,          "Run the given target."                                         }      
        ,   {nil, "arguments",  "vs",  nil,         "The target arguments"                                          }
        }
    }

    -- run lua: xmake lua
,   lua =
    {
        -- xmake l
        shortname = 'l'

        -- usage
    ,   usage = "xmake lua|l [options] [script] [arguments]"

        -- description
    ,   description = "Run the lua script."

        -- options
    ,   options = 
        {
            {'s', "string",     "k",  nil,          "Run the lua string script."                                    }

        ,   {}
        ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
        
        ,   {}
        ,   {nil, "script",     "v",  nil,          "Run the given lua script."
                                                  , "    - The script name from the xmake tool directory"
                                                  , "    - The script file"
                                                  , "    - The script string"                                       }      
        ,   {nil, "arguments",  "vs", nil,          "The script arguments"                                          }
        }
    }
}

-- prepare project
function main._prepare_project()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- init the project directory
    options.project = options.project or options._DEFAULTS.project or xmake._PROJECT_DIR
    options.project = path.absolute(options.project)
    assert(options.project)

    -- save the project directory
    xmake._PROJECT_DIR = options.project

    -- init the xmake.xproj file path
    options.file = options.file or options._DEFAULTS.file or "xmake.xproj"
    if not path.is_absolute(options.file) then
        options.file = path.absolute(options.file, options.project)
    end
    assert(options.file)

    -- init the build directory
    if options.buildir and path.is_absolute(options.buildir) then
        options.buildir = path.relative(options.buildir, xmake._PROJECT_DIR)
    end

    -- load xmake.xconf file first
    local errors = config.loadxconf()
    if not errors then
        -- load xmake.xproj file
        errors = project.loadxproj(options.file)
    end

    -- ok?
    return errors
end

-- done help
function main._done_help()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- done help
    if options.help then
    
        -- print menu
        option.print_menu(options._ACTION)

        -- ok
        return true

    -- done version
    elseif options.version then

        -- print title
        if option._MENU.title then
            print(option._MENU.title)
        end

        -- print copyright
        if option._MENU.copyright then
            print(option._MENU.copyright)
        end

        -- ok
        return true
    end
end

-- done global
function main._done_global()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- load global configure
    global.loadxconf()

    -- wrap the global configure for more convenient to get and set values
    local global_wrapped = {}
    setmetatable(global_wrapped, 
    {
        __index = function(tbl, key)
            return global.get(key)
        end,
        __newindex = function(tbl, key, val)
            global.set(key, val)
        end
    })

    -- probe the global platform configure 
    platform.probe(global_wrapped, true)

    -- done action    
    return action.done("global")
end

-- done option
function main._done_option()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- done help?
    if main._done_help() then
        return true
    end

    -- done lua?
    if options._ACTION == "lua" then
        return action.done("lua")
    end

    -- done global?
    if options._ACTION == "global" then
        return main._done_global()
    end

    -- prepare project
    local errors = main._prepare_project()
    if errors then
        -- error
        utils.error(errors)
        return false
    end

    -- xmake config?
    if options._ACTION == "config" then

        -- wrap the global configure for more convenient to get and set values
        local config_wrapped = {}
        setmetatable(config_wrapped, 
        {
            __index = function(tbl, key)
                return config.get(key)
            end,
            __newindex = function(tbl, key, val)
                config.set(key, val)
            end
        })

        -- probe the current platform configure
        platform.probe(config_wrapped, false)
    end

    -- make the current platform configure
    if not platform.make() then
        -- error
        utils.error("make platform configure: %s failed!", config.get("plat"))
        return false
    end

    -- enter the project directory
    if not os.cd(xmake._PROJECT_DIR) then
        -- error
        utils.error("not found project: %s!", xmake._PROJECT_DIR)
        return false
    end
 
    -- dump project 
    project.dump()

    -- dump platform
    platform.dump()

    -- done action    
    return action.done(options._ACTION or "build")
end

-- the main function
function main.done()

    -- init option first
    if not option.init(xmake._ARGV, menu) then 
        return -1
    end

    -- done option
    if not main._done_option() then 
        return -1
    end

    -- ok
    return 0
end

-- return module: main
return main
