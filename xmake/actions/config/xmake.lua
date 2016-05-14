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
-- @file        xmake.lua
--

-- define task
task("config")

    -- set category
    set_task_category("action")

    -- on run
    on_task_run("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake config|f [options] [target]"

                    -- description
                ,   description = "Configure the project."

                    -- xmake f
                ,   shortname = 'f'

                    -- options
                ,   options = 
                    {
                        {'p', "plat",       "kv", "$(host)",  "Compile for the given platform."                               

                                                                -- show the description of all platforms
                                                              , function () 

                                                                    -- import platform 
                                                                    import("core.platform.platform")

                                                                    -- make description
                                                                    local description = {}
                                                                    for i, plat in ipairs(platform.plats()) do
                                                                        description[i] = "    - " .. plat
                                                                    end

                                                                    -- get it
                                                                    return description
                                                                end                                                            }
                    ,   {'a', "arch",       "kv", "auto",       "Compile for the given architecture."                               

                                                                -- show the description of all architectures
                                                              , function () 

                                                                    -- import platform 
                                                                    import("core.platform.platform")

                                                                    -- make description
                                                                    local description = {}
                                                                    for i, plat in ipairs(platform.plats()) do
                                                                        description[i] = "    - " .. plat .. ":"
                                                                        for _, arch in ipairs(platform.archs(plat)) do
                                                                            description[i] = description[i] .. " " .. arch
                                                                        end
                                                                    end

                                                                    -- get it
                                                                    return description
                                                                end                                                            }
                    ,   {'m', "mode",       "kv", "release",    "Compile for the given mode." 
                                                              , "    - debug"
                                                              , "    - release"
                                                              , "    - profile"                                                 }
                    ,   {'k', "kind",       "kv", "static",     "Compile for the given target kind." 
                                                              , "    - static"
                                                              , "    - shared"
                                                              , "    - binary"                                                 }
                    ,   {nil, "host",       "kv", "$(host)",    "The current host environment."                                 }

                        -- show project menu options
                    ,   function () 

                            -- import project menu 
                            import("core.project.menu")

                            -- get project menu options 
                            return menu.options() 
                        end

                    ,   {}
                    ,   {nil, "make",       "kv", "auto",       "Set the make path."                                              }
                    ,   {nil, "ccache",     "kv", "auto",       "Enable or disable the c/c++ compiler cache."                     }

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

                        -- show platform menu options
                    ,   function () 

                            -- import platform menu
                            import("core.platform.menu")

                            -- get config menu options
                            return menu.options("config")
                        end

                    ,   {'o', "buildir",    "kv", "build",      "Set the build directory."                                      }


                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Configure for the given target."                               }
                    }
                })



