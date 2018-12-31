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
-- @file        xmake.lua
--

-- define platform
platform("mingw")

    -- set os
    set_os("windows")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("i386", "x86_64")

    -- set formats
    set_formats {static = "$(name).lib", object = "$(name).obj", shared = "$(name).dll", binary = "$(name).exe", symbol = "$(name).pdb"}

    -- on check project configuration
    on_config_check("config")

    -- on load
    on_load("load")

    -- set menu
    set_menu {
                config = 
                {   
                    {category = "MingW Configuration"                                     }
                ,   {nil, "mingw",          "kv", nil,          "The MingW SDK Directory" }
                }

            ,   global = 
                {   
                    {category = "MingW Configuration"                                     }
                ,   {nil, "mingw",          "kv", nil,          "The MingW SDK Directory" }
                }
            }
