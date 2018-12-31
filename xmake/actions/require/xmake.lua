--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        require.lua
--

-- define task
task("require")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake require [options] [packages]"

                -- description
            ,   description = "Install and update required packages."

                -- xmake q
            ,   shortname = 'q'

                -- options
            ,   options = 
                {
                    {'c', "clear",      "k",  nil,       "Clear all installed package caches."                                                       }
                ,   {'f', "force",      "k",  nil,       "Force to reinstall all package dependencies."                                              }
                ,   {'l', "list",       "k",  nil,       "List all package dependencies."                                                            }
                ,   {                                                                                                                                }
                ,   {nil, "info",       "k",  nil,       "Show the given package info."                                                              }
                ,   {'s', "search",     "k",  nil,       "Search for the given packages from repositories."                                          }
                ,   {nil, "unlink",     "k",  nil,       "Only unlink the installed packages."                                                       }
                ,   {nil, "uninstall",  "k",  nil,       "Uninstall the installed packages."                                                         }
                ,   {nil, "extra",      "kv", nil,       "Set the extra info of packages."                                                           }
                ,   {                                                                                                                                }
                ,   {nil, "requires",   "vs", nil,       "The package requires.",
                                                         ".e.g",
                                                         "    $ xmake require zlib tbox",
                                                         "    $ xmake require \"zlib >=1.2.11\" \"tbox master\"",
                                                         "    $ xmake require --extra=\"debug=true,system=false\" tbox"                              } 
                }
            } 
