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

    -- add rules
    add_rules("objc++")

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
        ,   "config.frameworkdirs"
        ,   "config.frameworks"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.frameworkdirs"
        ,   "target.frameworks"
        ,   "target.pcheader"
        ,   "target.pcxxheader"
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
        ,   "option.frameworkdirs"
        ,   "option.frameworks"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "toolchain.frameworkdirs"
        ,   "toolchain.frameworks"
        }
    ,   binary =
        {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.frameworkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.strip"
        ,   "option.symbols"
        ,   "option.linkdirs"
        ,   "option.rpathdirs"
        ,   "option.frameworkdirs"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "option.frameworks"
        ,   "toolchain.frameworks"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.strip"
        ,   "option.symbols"
        ,   "option.linkdirs"
        ,   "option.frameworkdirs"
        ,   "toolchain.linkdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "option.frameworks"
        ,   "toolchain.frameworks"
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
    }

    -- set menu
    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"                             }
                ,   {nil, "mm",            "kv", nil,          "The Objc Compiler"                                  }
                ,   {nil, "mxx",           "kv", nil,          "The Objc++ Compiler"                                }

                ,   {category = "Cross Complation Configuration/Linker Configuration"                               }
                ,   {nil, "ld",            "kv", nil,          "The Linker"                                         }
                ,   {nil, "ar",            "kv", nil,          "The Static Library Linker"                          }
                ,   {nil, "sh",            "kv", nil,          "The Shared Library Linker"                          }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration"                       }
                ,   {nil, "mflags",        "kv", nil,          "The Objc Compiler Flags"                            }
                ,   {nil, "mxflags",       "kv", nil,          "The Objc/c++ Compiler Flags"                        }
                ,   {nil, "mxxflags",      "kv", nil,          "The Objc++ Compiler Flags"                          }

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




