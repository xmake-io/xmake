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
-- @file        deps.lua
--

-- define task
task("deps")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake deps [options] [packages]"

                -- description
            ,   description = "Install package dependencies."

                -- xmake d
            ,   shortname = 'd'

                -- options
            ,   options = 
                {
                    {'i', "install",    "k",  nil,       "Install and update outdated package dependencies."                           }
                ,   {'c', "clear",      "k",  nil,       "Clear all installed package caches."                                         }
                ,   {'f', "force",      "k",  nil,       "Force to reinstall all package dependencies."                                }
                ,   {'l', "list",       "k",  nil,       "List all package dependencies."                                              }
                ,   {                                                                                                                  }
                ,   {nil, "info",       "k",  nil,       "Show the given package info."                                                }
                ,   {'g', "global",     "k",  nil,       "Install or clear packages in the global package directory. (default: local)" }
                ,   {'s', "search",     "k",  nil,       "Search for the given packages from repositories."                            }
                ,   {                                                                                                                  }
                ,   {nil, "packages",   "vs", nil,       "The packages."                                                               }
                }
            } 
