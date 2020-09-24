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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define language
language("cuda")

    -- set source file kinds
    set_sourcekinds {cu = ".cu"}

    -- set source file flags
    set_sourceflags {cu = "cuflags"}

    -- set target kinds
    set_targetkinds {gpucode = "culd", binary = "ld", static = "ar", shared = "sh"}

    -- set target flags
    set_targetflags {gpucode = "culdflags", binary = "ldflags", static = "arflags", shared = "shflags"}

    -- set language kinds
    set_langkinds {cu = "cu"}

    -- set mixing kinds
    set_mixingkinds("cu", "cc", "cxx", "as")

    -- add rules
    add_rules("cuda")

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
        ,   "target.includedirs"
        ,   "target.languages"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "option.symbols"
        ,   "option.warnings"
        ,   "option.optimize:check"
        ,   "option.vectorexts:check"
        ,   "option.includedirs"
        ,   "option.languages"
        ,   "option.defines"
        ,   "option.undefines"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
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
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "toolchain.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   static =
        {
            "target.strip"
        ,   "target.symbols"
        }
    ,   gpucode =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "option.linkdirs"
        ,   "toolchain.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
        ,   "toolchain.syslinks"
        }
    }

    -- set menu
    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"         }
                ,   {nil, "cu",         "kv", nil,          "The Cuda Compiler"                 }
                ,   {nil, "cu-ccbin",   "kv", nil,          "The Cuda Host C++ Compiler"        }
                ,   {nil, "culd",      "kv", nil,          "The Cuda Linker"                   }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration"   }
                ,   {nil, "cuflags",    "kv", nil,          "The Cuda Compiler Flags"           }
                ,   {nil, "culdflags",  "kv", nil,          "The Cuda Linker Flags"             }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"    }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                }
                ,   {nil, "syslinks",   "kv", nil,          "The System Link Libraries"         }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"       }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"    }
                }
            }

