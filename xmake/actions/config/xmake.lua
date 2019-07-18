--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
                ,   {nil, "menu",       "k", nil,         "Configure project with a menu-driven user interface."          }
                ,   {nil, "require",    "kv", nil,        "Require all dependent packages?",
                                                          "  - y: force to enable",
                                                          "  - n: disable"                                                }

                ,   {category = "."}
                ,   {'p', "plat",       "kv", "$(host)",  "Compile for the given platform."                               
                                                          , values = function ()
                                                                return import("core.platform.platform").plats()
                                                            end                                                           }
                ,   {'a', "arch",       "kv", "auto",       "Compile for the given architecture."                               

                                                            -- show the description of all architectures
                                                          , function () 

                                                                -- import platform 
                                                                import("core.platform.platform")

                                                                -- make description
                                                                local description = {}
                                                                for i, plat in ipairs(platform.plats()) do
                                                                    local archs = platform.archs(plat)
                                                                    if archs then
                                                                        description[i] = "    - " .. plat .. ":"
                                                                        for _, arch in ipairs(archs) do
                                                                            description[i] = description[i] .. " " .. arch
                                                                        end
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
                                                          , values = function () 
                                                                return {"static", "shared", "binary"}
                                                            end                                                            }
                ,   {nil, "host",       "kv", "$(host)",    "The Current Host Environment."                                }

                    -- show project menu options
                ,   function () 

                        -- import project menu 
                        import("core.project.menu")

                        -- get project menu options 
                        return menu.options() 
                    end

                ,   {category = "Cross Complation Configuration"}
                ,   {nil, "cross",      "kv", nil,          "The Cross Toolchains Prefix"   
                                                          , "e.g."
                                                          , "    - i386-mingw32-"
                                                          , "    - arm-linux-androideabi-"                                  }
                ,   {nil, "bin",        "kv", nil,          "The Cross Toolchains Bin Directory" 
                                                          , "e.g."
                                                          , "    - sdk/bin (/arm-linux-gcc ..)"                             }
                ,   {nil, "sdk",        "kv", nil,          "The Cross SDK Directory" 
                                                          , "e.g."
                                                          , "    - sdk/bin"
                                                          , "    - sdk/lib"
                                                          , "    - sdk/include"                                             }

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

                ,   {category = "Other Configuration"}
                ,   {nil, "debugger",   "kv", "auto",       "The Debugger"                                                  }
                ,   {nil, "ccache",     "kv", true,         "Enable or disable the c/c++ compiler cache."         
                                                    ,       "    --ccache=[y|n]"                                            }
                ,   {'o', "buildir",    "kv", "build",      "Set the build directory."                                      }

                ,   {}
                ,   {nil, "target",     "v",  nil,          "Configure for the given target."                               }
                }
            }



