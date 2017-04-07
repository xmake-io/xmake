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
-- @file        repo.lua
--

-- define task
task("repo")

    -- set category
    set_category("plugin")

    -- on run
    on_run(function ()

        -- TODO
    end)

    -- set menu
    set_menu {
                -- usage
                usage = "xmake repo [options]"

                -- description
            ,   description = "Manage the package repository."

                -- options
            ,   options = 
                {
                    {'i', "install",    "k", nil,        "Install packages."                                 }      
                ,   {'r', "uninstall",  "k",  nil,       "Uninstall packages."                               }      
                ,   {'u', "update",     "k",  nil,       "Update packages."                                  }      
                ,   {'l', "list",       "k",  nil,       "List all installed packages."                      }      
                ,   {'i', "info",       "k",  nil,       "Show the given package info."                      }      
                ,   {'s', "search",     "k",  nil,       "Search the given packages from remote repository." }      
                ,   {}
                ,   {nil, "packages",   "vs", nil,       "The packages."                                     }
                }
            } 
