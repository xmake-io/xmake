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
local main = {}

-- load modules
local utils     = require("base/utils")
local option    = require("base/option")

-- init the option menu
local menu =
{
    -- title
    title = "XMake " .. xmake._VERSION .. ", The Automatic Cross-platform Build Tool"

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
        actions = {"create", "config", "install", "clean"}

        -- options
    ,   options = 
        {
            {'b', "build",      "k",  nil,          "Build project. This is default building mode and optional."    }
        ,   {'u', "update",     "k",  nil,          "Only relink and update the binary files."                      }
        ,   {'r', "rebuild",    "k",  nil,          "Rebuild the project."                                          }

        ,   {}
        ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
        ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                  , "Search priority:"
                                                  , "    1. the given command argument"
                                                  , "    2. the envirnoment variable: XMAKE_PROJECT_DIR"
                                                  , "    3. the current directory"                                  }


        ,   {}
        ,   {nil, "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {'v', "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }

        ,   {}
        ,   {nil, "target",     "v",  nil,          "Build the given target"                     
                                                  , "Build all targets if not exists."                              }
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
        ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
        ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                  , "Search priority:"
                                                  , "    1. the given command argument"
                                                  , "    2. the envirnoment variable: XMAKE_PROJECT_DIR"
                                                  , "    3. the current directory"                                  }
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
        ,   {nil, "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {'v', "version",    "k",  nil,          "Print the version number and exit."                            }
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
            {'p', "plat",       "kv", "auto",       "Compile for the given platform."                               }
        ,   {'a', "arch",       "kv", "auto",       "Compile for the given architecture."                           }
        ,   {'d', "debug",      "k",  nil,          "Compile for the debugging mode."                               }
        ,   {'s', "small",      "k",  nil,          "Compile for the small mode."                                   }
        ,   {nil, "profile",    "k",  nil,          "Compile for the profiling mode and disable the debugging mode."}

        ,   {}
        ,   {nil, "output",     "kv", "build",      "Set the build output directory"                                }
        ,   {nil, "packages",   "kv", "pkg",        "Set the packages directory"                                    }

        ,   {}
        ,   {nil, "cc",         "kv", nil,          "The c compiler"                                                }
        ,   {nil, "cxx",        "kv", nil,          "The c++ compiler"                                              }
        ,   {nil, "mm",         "kv", nil,          "The objc compiler"                                             }
        ,   {nil, "mxx",        "kv", nil,          "The objc++ compiler"                                           }
        ,   {nil, "ld",         "kv", nil,          "The linker"                                                    }
        ,   {nil, "as",         "kv", nil,          "The assembler"                                                 }
        ,   {nil, "ar",         "kv", nil,          "The library creator"                                           }

        ,   {}
        ,   {nil, "cflags",     "kv", nil,          "The c compiler flags"                                          }
        ,   {nil, "cxflags",    "kv", nil,          "The c/c++ compiler flags"                                      }
        ,   {nil, "cxxflags",   "kv", nil,          "The c++ compiler flags"                                        }
        ,   {nil, "mflags",     "kv", nil,          "The objc compiler flags"                                       }
        ,   {nil, "mxflags",    "kv", nil,          "The objc/c++ compiler flags"                                   }
        ,   {nil, "mxxflags",   "kv", nil,          "The objc++ compiler flags"                                     }
        ,   {nil, "asflags",    "kv", nil,          "The assembler flags"                                           }
        ,   {nil, "ldflags",    "kv", nil,          "The linker flags"                                              }
        ,   {nil, "arflags",    "kv", nil,          "The library creator flags"                                     }

        ,   {}
        ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
        ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                  , "Search priority:"
                                                  , "    1. the given command argument"
                                                  , "    2. the envirnoment variable: XMAKE_PROJECT_DIR"
                                                  , "    3. the current directory"                                  }


        ,   {}
        ,   {nil, "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {'v', "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
 
        ,   {}
        ,   {nil, "target",     "v",  nil,          "Configure for the given target."             
                                                  , "Configure for all targets if not exists."                      }
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
            {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
        ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                  , "Search priority:"
                                                  , "    1. the given command argument"
                                                  , "    2. the envirnoment variable: XMAKE_PROJECT_DIR"
                                                  , "    3. the current directory"                                  }


        ,   {}
        ,   {nil, "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {'v', "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
 
        ,   {}
        ,   {nil, "target",     "v",  nil,          "Install the given target."                               
                                                  , "Install all targets if not exists."                            }
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
            {nil, "verbose",    "k",  nil,          "Print lots of verbose information."                            }
        ,   {'v', "version",    "k",  nil,          "Print the version number and exit."                            }
        ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
        
        ,   {}
        ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
        ,   {nil, nil,          "v",  nil,          "Change to the given project directory."
                                                  , "Search priority:"
                                                  , "    1. the last argument of the current command: ..."
                                                  , "    2. the envirnoment variable: XMAKE_PROJECT_DIR"
                                                  , "    3. the current directory"                                  }
 
        ,   {}
        ,   {nil, "target",     "v",  nil,          "Clean for the given target."
                                                  , "Clean all targets if not exists."                              }
        }
    }
}

-- the main function
function main.done()

    -- done option first
    if not option.done(xmake._ARGV, menu) then 
        return -1
    end
    
    -- ok
    return 0
end

-- return module: main
return main
