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

task("test")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake test [options] [target] [arguments]",
        description = "Run the project tests.",
        options = {
            {'g', "group",      "kv",  nil  , "Run all tests of the given group. It support path pattern matching.",
                                              "e.g.",
                                              "    xmake test -g test",
                                              "    xmake test -g test_*",
                                              "    xmake test --group=benchmark/*"                                  },
            {'w', "workdir",    "kv",  nil  , "Work directory of running targets, default is folder of targetfile",
                                              "e.g.",
                                              "    xmake test -w .",
                                              "    xmake test --workdir=`pwd`"                                      },
            {'j', "jobs",       "kv", tostring(os.default_njob()), "Set the number of parallel compilation jobs."   },
            {'r', "rebuild",    "k",  nil   , "Rebuild the target."                                                 },
            {},
            {nil, "tests",     "vs",  nil   , "The test names. It support pattern matching.",
                                              "e.g.",
                                              "    xmake test foo",
                                              "    xmake test */foo",
                                              "    xmake test targetname/*"                                         }
        }
    }



