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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

language("c++")
    add_rules("c++")
    set_sourcekinds {cc = ".c", cxx = {".cpp", ".cc", ".cxx"}}
    set_sourceflags {cc = {"cflags", "cxflags"}, cxx = {"cxxflags", "cxflags"}}
    set_targetkinds {binary = "ld", static = "ar", shared = "sh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds   {c = "cc", cxx = "cxx"}
    set_mixingkinds("cc", "cxx", "as", "mrc")

    on_load("load")
    on_check_main("check_main")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "config.frameworkdirs"
        ,   "config.frameworks"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.fpmodels"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.runtimes"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.frameworkdirs"
        ,   "target.frameworks"
        ,   "target.exceptions"
        ,   "target.pcheader"
        ,   "target.pcxxheader"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "toolchain.frameworkdirs"
        ,   "toolchain.frameworks"
        ,   "target.sysincludedirs"
        ,   "toolchain.sysincludedirs"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "target.optimize:check"
        ,   "target.runtimes"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "target.optimize:check"
        ,   "target.runtimes"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
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
                    {category = "Cross Complation Configuration/Compiler Configuration"                             }
                ,   {nil, "cc",            "kv", nil,          "The C Compiler"                                     }
                ,   {nil, "cxx",           "kv", nil,          "The C++ Compiler"                                   }
                ,   {nil, "cpp",           "kv", nil,          "The C Preprocessor"                                 }

                ,   {category = "Cross Complation Configuration/Linker Configuration"                               }
                ,   {nil, "ld",            "kv", nil,          "The Linker"                                         }
                ,   {nil, "ar",            "kv", nil,          "The Static Library Linker"                          }
                ,   {nil, "sh",            "kv", nil,          "The Shared Library Linker"                          }
                ,   {nil, "ranlib",        "kv", nil,          "The Static Library Index Generator"                 }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration"                       }
                ,   {nil, "cflags",        "kv", nil,          "The C Compiler Flags"                               }
                ,   {nil, "cxflags",       "kv", nil,          "The C/C++ compiler Flags"                           }
                ,   {nil, "cxxflags",      "kv", nil,          "The C++ Compiler Flags"                             }

                ,   {category = "Cross Complation Configuration/Linker Flags Configuration"                         }
                ,   {nil, "ldflags",       "kv", nil,          "The Binary Linker Flags"                            }
                ,   {nil, "arflags",       "kv", nil,          "The Static Library Linker Flags"                    }
                ,   {nil, "shflags",       "kv", nil,          "The Shared Library Linker Flags"                    }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"                        }
                ,   {nil, "links",         "kv", nil,          "The Link Libraries"                                 }
                ,   {nil, "syslinks",      "kv", nil,          "The System Link Libraries"                          }
                ,   {nil, "linkdirs",      "kv", nil,          "The Link Search Directories"                        }
                ,   {nil, "includedirs",   "kv", nil,          "The Include Search Directories"                     }
                ,   {nil, "frameworks",    "kv", nil,          "The Frameworks"                                     }
                ,   {nil, "frameworkdirs", "kv", nil,          "The Frameworks Search Directories"                  }
                }
            }






