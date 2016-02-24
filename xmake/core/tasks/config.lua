-- define task
task("config")

    -- set category
    set_task_category("action")

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
                        {'c', "clean",      "k", nil,           "Clean the cached configure and configure all again."           }

                    ,   {}
--[[                    ,   {'p', "plat",       "kv", xmake._HOST,  "Compile for the given platform."                               
                                                              , function () 
                                                                    local descriptions = {}
                                                                    local plats = platform.plats()
                                                                    if plats then
                                                                        for i, plat in ipairs(plats) do
                                                                            descriptions[i] = "    - " .. plat
                                                                        end
                                                                    end
                                                                    return descriptions
                                                                end                                                            }
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
                                                                end                                                            }]]
                    ,   {'m', "mode",       "kv", "release",    "Compile for the given mode." 
                                                              , "    - debug"
                                                              , "    - release"
                                                              , "    - profile"                                                 }
                    ,   {'k', "kind",       "kv", "static",     "Compile for the given target kind." 
                                                              , "    - static"
                                                              , "    - shared"
                                                              , "    - binary"                                                 }
--                    ,   {nil, "host",       "kv", xmake._HOST,  "The current host environment."                                 }

                        -- the options for project
--                    ,   function () return project.menu() end

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
--                    ,   function () return platform.menu("config") end

                    ,   {}
                    ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }
                    ,   {'o', "buildir",    "kv", "build",      "Set the build directory."                                      }


                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Configure for the given target."                               }
                    }
                })



