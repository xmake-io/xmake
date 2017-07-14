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
language("objc++")

    -- set source file kinds
    set_sourcekinds {mm = ".m", mxx = ".mm"}

    -- set source file flags
    set_sourceflags {mm = {"mflags", "mxflags"}, mxx = {"mxxflags", "mxflags"}}

    -- set target kinds
    set_targetkinds {binary = "ld", static = "ar", shared = "sh"}

    -- set target flags
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}

    -- set language kinds
    set_langkinds {m = "mm", mxx = "mxx"}

    -- set mixing kinds
    set_mixingkinds("mm", "mxx", "cc", "cxx", "as")

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
        ,   "config.frameworks"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.frameworks"
        ,   "option.symbols"
        ,   "option.warnings"
        ,   "option.optimize:check"
        ,   "option.vectorexts:check"
        ,   "option.languages"
        ,   "option.includedirs"
        ,   "option.defines"
        ,   "option.undefines"
        ,   "option.defines_if_ok"
        ,   "option.undefines_if_ok"
        ,   "option.frameworks"
        ,   "platform.includedirs"
        ,   "platform.defines"
        ,   "platform.undefines"
        ,   "platform.frameworks"
        }
    ,   binary =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.strip"
        ,   "option.symbols"
        ,   "option.linkdirs"
        ,   "option.rpathdirs"
        ,   "platform.linkdirs"
        ,   "platform.rpathdirs"
        ,   "config.links"
        ,   "config.frameworks"
        ,   "target.links"
        ,   "target.frameworks"
        ,   "option.links"
        ,   "option.frameworks"
        ,   "platform.links"
        ,   "platform.frameworks"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.strip"
        ,   "option.symbols"
        ,   "option.linkdirs"
        ,   "platform.linkdirs"
        ,   "config.links"
        ,   "config.frameworks"
        ,   "target.links"
        ,   "target.frameworks"
        ,   "option.links"
        ,   "option.frameworks"
        ,   "platform.links"
        ,   "platform.frameworks"
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
                    {}
                ,   {nil, "mm",         "kv", nil,          "The Objc Compiler"                     }
                ,   {nil, "mxx",        "kv", nil,          "The Objc++ Compiler"                   }
                ,   {nil, "mflags",     "kv", nil,          "The Objc Compiler Flags"               }
                ,   {nil, "mxflags",    "kv", nil,          "The Objc/c++ Compiler Flags"           }
                ,   {nil, "mxxflags",   "kv", nil,          "The Objc++ Compiler Flags"             }

                ,   {}
                ,   {nil, "ld",         "kv", nil,          "The Linker"                            }
                ,   {nil, "ldflags",    "kv", nil,          "The Binary Linker Flags"               }

                ,   {}
                ,   {nil, "ar",         "kv", nil,          "The Static Library Linker"             }
                ,   {nil, "arflags",    "kv", nil,          "The Static Library Linker Flags"       }

                ,   {}
                ,   {nil, "sh",         "kv", nil,          "The Shared Library Linker"             }
                ,   {nil, "shflags",    "kv", nil,          "The Shared Library Linker Flags"       }

                ,   {}
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                    }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"           }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"        }
                ,   {nil, "frameworks", "kv", nil,          "The Link Frameworks"                   }
                }
            }




