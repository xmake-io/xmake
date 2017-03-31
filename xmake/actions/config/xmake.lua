--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define task
task("config")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake config|f [options] [target]"

                -- description
            ,   description = "Configure the project."

                -- xmake f
            ,   shortname = 'f'

                -- options
            ,   options = 
                {
                    {'c', "clean",      "k", nil,         "Clean the cached configure and configure all again."           }

                ,   {}
                ,   {'p', "plat",       "kv", "$(host)",  "Compile for the given platform."                               

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
                                                          , "    - ... (custom)"                                           } 
                ,   {'k', "kind",       "kv", "static",     "Compile for the given target kind." 
                                                          , "    - static"
                                                          , "    - shared"
                                                          , "    - binary"                                                 }
                ,   {nil, "host",       "kv", "$(host)",    "The current host environment."                                }

                    -- show project menu options
                ,   function () 

                        -- import project menu 
                        import("core.project.menu")

                        -- get project menu options 
                        return menu.options() 
                    end

                ,   {}
                ,   {nil, "ccache",     "kv", "auto",       "Enable or disable the c/c++ compiler cache."                   }

                ,   {}
                ,   {nil, "cross",      "kv", nil,          "The cross toolchains prefix"   
                                                          , ".e.g"
                                                          , "    - i386-mingw32-"
                                                          , "    - arm-linux-androideabi-"                                  }
                ,   {nil, "toolchains", "kv", nil,          "The cross toolchains directory" 
                                                          , ".e.g"
                                                          , "    - sdk/bin (/arm-linux-gcc ..)"                             }
                ,   {nil, "sdk",        "kv", nil,          "The cross sdk directory" 
                                                          , ".e.g"
                                                          , "    - sdk/bin (toolchains)"
                                                          , "    - sdk/lib"
                                                          , "    - sdk/include"                                             }

                ,   {}
                ,   {nil, "dg",         "kv", "auto",       "The Debugger"                                                  }

                    -- show language menu options
                ,   function () 

                        -- import language menu
                        import("core.language.menu")

                        -- get config menu options
                        return menu.options("config")
                    end

                    -- show platform menu options
                ,   function () 

                        -- import platform menu
                        import("core.platform.menu")

                        -- get config menu options
                        return menu.options("config")
                    end

                ,   {'o', "buildir",    "kv", "build",      "Set the build directory."                                      }

                ,   {}
                ,   {nil, "target",     "v",  nil,          "Configure for the given target."                               }
                }
            }



