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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      wuzhenqing
-- @file        xmake.lua
--

language("ascendc")
    add_rules("ascendc")
    set_sourcekinds {asc = ".asc", aicpu = ".aicpu"}
    set_sourceflags {asc = "ascflags", aicpu = "aicpuflags"}
    set_targetkinds {binary = "ascld", static = "ar", shared = "ascsh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds {ascendc = "asc"}
    set_mixingkinds("asc", "aicpu", "cc", "cxx", "as")

    on_load("load")
    on_check_main("check_main")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "target.runtimes"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "target.sysincludedirs"
        ,   "toolchain.sysincludedirs"
        }
    ,   binary = {
            "target.runtimes"
        ,   "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "target.optimize:check"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.links"
            -- move it before target.links to keep package/dependency order correct
        ,   "target.linkgroups"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared = {
            "target.runtimes"
        ,   "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "target.optimize:check"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "target.linkgroups"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   static = {
            "target.strip"
        ,   "target.symbols"
        }
    }

    set_menu {
                config =
                {
                    {category = "Cross Compilation Configuration/Compiler Flags Configuration"                       }
                ,   {nil, "ascflags",      "kv", nil,          "The Ascend C Kernel Compiler Flags"                 }
                ,   {nil, "aicpuflags",    "kv", nil,          "The Ascend C AI-CPU Compiler Flags"                 }

                ,   {category = "Cross Compilation Configuration/Linker Flags Configuration"                         }
                ,   {nil, "ldflags",       "kv", nil,          "The Binary Linker Flags"                            }
                ,   {nil, "arflags",       "kv", nil,          "The Static Library Linker Flags"                    }
                ,   {nil, "shflags",       "kv", nil,          "The Shared Library Linker Flags"                    }

                ,   {category = "Cross Compilation Configuration/Builtin Flags Configuration"                        }
                ,   {nil, "links",         "kv", nil,          "The Link Libraries"                                 }
                ,   {nil, "syslinks",      "kv", nil,          "The System Link Libraries"                          }
                ,   {nil, "linkdirs",      "kv", nil,          "The Link Search Directories"                        }
                ,   {nil, "includedirs",   "kv", nil,          "The Include Search Directories"                     }
                }
            }
