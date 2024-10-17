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

task("build")
    set_category("main")
    on_run("main")
    set_menu {
                usage = "xmake [task] [options] [target]"
            ,   description = "Build targets if no given tasks."
            ,   shortname = 'b'
            ,   options =
                {
                    {nil, "version",    "k",  nil   , "Print the version number and exit."                            }
                ,   {'b', "build",      "k",  nil   , "Build target. This is default building mode and optional."     }
                ,   {'r', "rebuild",    "k",  nil   , "Rebuild the target."                                           }
                ,   {'a', "all",        "k",  nil   , "Build all targets."                                            }
                ,   {nil, "shallow",    "k",  nil   , "Only re-build the given targets without dependencies."         }
                ,   {'g', "group",      "kv", nil   , "Build all targets of the given group. It support path pattern matching.",
                                                      "e.g.",
                                                      "    xmake -g test",
                                                      "    xmake -g test_*",
                                                      "    xmake --group=benchmark/*"                                 }
                ,   {nil, "dry-run",    "k",  nil   , "Dry run to build target."                                      }

                ,   {}
                ,   {'j', "jobs",       "kv", tostring(os.default_njob()),
                                                      "Set the number of parallel compilation jobs."                  }
                ,   {nil, "linkjobs",   "kv", nil,    "Set the number of parallel link jobs."                         }
                ,   {'w', "warning",    "k",  false , "Enable the warnings output. (deprecated)"                      }
                ,   {nil, "linkonly",   "k",  false , "Only link targets if object files have been compiled."         }
                ,   {nil, "files",      "kv", nil   , "Build the given source files.",
                                                      "e.g. ",
                                                      "    - xmake --files=src/main.c",
                                                      "    - xmake --files='src/*.c' [target]",
                                                      "    - xmake --files='src/**.c|excluded_file.c'",
                                                      "    - xmake --files='src/main.c" .. path.envsep() .. "src/test.c'"  }

                ,   {}
                ,   {nil, "target",     "v",  nil   , "The target name. It will build all default targets if this parameter is not specified."
                                                    , values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end }
                }
            }



