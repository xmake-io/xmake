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

-- define language
language("rust")

    -- set source file kinds
    set_sourcekinds {rc = ".rs"}

    -- set source file flags
    set_sourceflags {rc = "rcflags"}

    -- set target kinds
    set_targetkinds {binary = "rc-ld", static = "rc-ar", shared = "rc-sh"}

    -- set target flags
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}

    -- set language kinds
    set_langkinds {rust = "rc"}

    -- set mixing kinds
    set_mixingkinds("rc")

    -- on load
    on_load("load")

    -- on check_main
    on_check_main("check_main")

    -- set name flags
    set_nameflags 
    {
        object =
        {
            "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        }
    ,   binary =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "option.rpathdirs"
        ,   "platform.linkdirs"
        ,   "platform.rpathdirs"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "platform.linkdirs"
        }
    ,   static = 
        {
            "target.strip"
        ,   "target.symbols"
        }
    }

    -- set menu
    set_menu {
                config = 
                {   
                    {                                                                          }
                ,   {nil, "rc",         "kv", nil,          "The Rust Compiler"                }
                ,   {nil, "rc-ld",      "kv", nil,          "The Rust Linker"                  }
                ,   {nil, "rc-ar",      "kv", nil,          "The Rust Static Library Archiver" }
                ,   {nil, "rc-sh",      "kv", nil,          "The Rust Shared Library Linker"   }

                ,   {                                                                          }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"      }
                }
            } 

