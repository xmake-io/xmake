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
task("global")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake global|g [options] [target]"

                -- description
            ,   description = "Configure the global options for xmake."

                -- xmake g
            ,   shortname = 'g'

                -- options
            ,   options = 
                {
                    {'c', "clean",      "k", nil,       "Clean the cached configure and configure all again."     }
                ,   {nil, "menu",       "k", nil,       "Configure with a menu-driven user interface."            }

                ,   {category = "."}
                ,   {nil, "theme",      "kv", "default","The theme name."                                         }
                ,   {nil, "debugger",   "kv", "auto",   "The Debugger Program Path."                              }

                    -- show platform menu options
                ,   {category = "Platform Configuration"}
                ,   function () 

                        -- import platform menu
                        import("core.platform.menu")

                        -- get global menu options
                        return menu.options("global")
                    end

                }
            }



