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
task("build")

    -- set category
    set_category("main")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake [task] [options] [target]"

                -- description
            ,   description = "Build targets if no given tasks."

                -- options
            ,   options = 
                {
                    {'b', "build",      "k",  nil,          "Build target. This is default building mode and optional."     }
                ,   {'r', "rebuild",    "k",  nil,          "Rebuild the target."                                           }
                ,   {'a', "all",        "k",  nil,          "Build all targets."                                            }

                ,   {}
                ,   {'j', "jobs",       "kv", "4",          "Specifies the number of jobs to build simultaneously."         }
               
                ,   {}
                ,   {nil, "target",     "v",  nil,          "Build the given target."                                       } 
                }
            }



