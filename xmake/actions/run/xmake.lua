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

-- define task
task("run")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake run|r [options] [target] [arguments]"

                -- description
            ,   description = "Run the project target."

                -- xmake r
            ,   shortname = 'r'

                -- options
            ,   options =
                {
                    {'d', "debug",      "k",   nil  , "Run and debug the given target."                                    }
                ,   {'a', "all",        "k",   nil  , "Run all targets."                                                   }
                ,   {'g', "group",      "kv",  nil  , "Run all targets of the given group. It support path pattern matching.",
                                                      "e.g.",
                                                      "    xmake run -g test",
                                                      "    xmake run -g test_*",
                                                      "    xmake run --group=benchmark/*"                                  }
                ,   {'w', "workdir",    "kv",  nil  , "Work directory of running targets, default is folder of targetfile",
                                                      "e.g.",
                                                      "    xmake run -w .",
                                                      "    xmake run --workdir=`pwd`"                                      }
                ,   {'j', "jobs",       "kv", "1",    "Set the number of parallel compilation jobs."                       }
                ,   {nil, "detach",     "k", nil,     "Run targets in detached processes."                                 }
                ,   {}
                ,   {nil, "target",     "v",   nil  , "The target name. It will run all default targets if this parameter is not specified."
                                                    , values = function (complete, opt)
                                                            return import("private.utils.complete_helper.runable_targets")(complete, opt)
                                                        end }

                ,   {nil, "arguments",  "vs",  nil  , "The target arguments"                                               }
                }
            }



