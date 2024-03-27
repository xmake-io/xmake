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

task("uninstall")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake uninstall|u [options] [target]",
        description = "Uninstall the project binary files.",
        shortname = 'u',
        options = {
            {nil, "installdir", "kv", nil   , "Set the install directory.",
                                              "e.g.",
                                              "    $ xmake uninstall -o /usr/local",
                                              "or  $ DESTDIR=/usr/local xmake uninstall",
                                              "or  $ INSTALLDIR=/usr/local xmake uninstall" },
            {'g', "group",      "kv",  nil  , "Uninstall all targets of the given group. It support path pattern matching.",
                                              "e.g.",
                                              "    xmake uninstall -g test",
                                              "    xmake uninstall -g test_*",
                                              "    xmake uninstall --group=benchmark/*"     },
            {'p', "prefix",     "kv", nil   , "Set the prefix directory.",
                                              "e.g.",
                                              "    $ xmake uninstall --prefix=local",
                                              "or  $ PREFIX=local xmake uninstall"          },
            {nil, "admin",      "k",  nil   , "Try to request administrator permission to uninstall"},
            {                                                                               },
            {nil, "target",     "v",  nil   , "The target name. It will uninstall all default targets if this parameter is not specified.",
                                              values = function (complete, opt)
                                                return import("private.utils.complete_helper.targets")(complete, opt)
                                              end}
        }
    }



