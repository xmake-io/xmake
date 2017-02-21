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
language("dlang")

    -- set source file kinds
    set_sourcekinds {dd = ".d"}

    -- set source file flags
    set_sourceflags {dd = "dflags"}

    -- set target kinds
    set_targetkinds {binary = "dd-ld", static = "dd-ar", shared = "dd-sh"}

    -- set target flags
    set_targetflags {binary = "dd-ldflags", static = "dd-arflags", shared = "dd-shflags"}

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
                    {                                                                                 }
                ,   {nil, "dd",         "kv", nil,          "The Dlang Compiler"                      }
                ,   {nil, "dflags",     "kv", nil,          "The Dlang Compiler Flags"                }

                ,   {                                                                                 }
                ,   {nil, "dd-ld",      "kv", nil,          "The Dlang Linker"                        }
                ,   {nil, "dd-ldflags", "kv", nil,          "The Dlang Linker Flags"                  }

                ,   {                                                                                 }
                ,   {nil, "dd-ar",      "kv", nil,          "The Dlang Static Library Archiver"       }
                ,   {nil, "dd-arflags", "kv", nil,          "The Dlang Static Library Archvier Flags" }


                ,   {                                                                                 }
                ,   {nil, "dd-sh",      "kv", nil,          "The Dlang Shared Library Linker"         }
                ,   {nil, "dd-shflags", "kv", nil,          "The Dlang Shared Library Linker Flags"   }

                -- TODO
                ,   {                                                                                 }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                      }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"             }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"          }
                }
            } 

