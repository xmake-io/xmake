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
language("golang")

    -- set source file kinds
    set_sourcekinds {gc = ".go"}

    -- set source file flags
    set_sourceflags {gc = "gcflags"}

    -- set target kinds
    set_targetkinds {binary = "gc-ld", static = "gc-ar"}

    -- set target flags
    set_targetflags {binary = "ldflags", static = "arflags"}

    -- set language kinds
    set_langkinds {go = "gc"}

    -- set mixing kinds
    set_mixingkinds("gc")

    -- on load
    on_load("load")

    -- on check_main
    on_check_main("check_main")

    -- set name flags
    set_nameflags 
    {
        object =
        {
            "config.includedirs"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.includedirs"
        ,   "platform.includedirs"
        ,   "platform.defines"
        ,   "platform.undefines"
        }
    ,   binary =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "platform.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "platform.links"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "platform.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "platform.links"
        }
    }

    -- set menu
    set_menu {
                config = 
                {   
                    {                                                                                }
                ,   {nil, "go",         "kv", nil,          "The Golang Compiler"                    }
                ,   {nil, "gc-ld",      "kv", nil,          "The Golang Linker"                      }
                ,   {nil, "go-ar",      "kv", nil,          "The Golang Static Library Linker"       }

                ,   {                                                                                }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                     }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"            }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"         }
                }
            } 

