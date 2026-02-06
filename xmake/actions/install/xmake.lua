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
-- @author      ruki
-- @file        xmake.lua
--

task("install")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake install|i [options] [target]",
        description = "Package and install the target binary files.",
        shortname = 'i',
        options = {
            {'o', "installdir", "kv", nil   , "Set the install directory.",
                                              "e.g.",
                                              "    $ xmake install -o /usr/local",
                                              "or  $ DESTDIR=/usr/local xmake install",
                                              "or  $ INSTALLDIR=/usr/local xmake install" },
            {nil, "bindir",     "kv", nil   , "Set install binaries directory in INSTALLDIR/DIR. (default: ${installdir}/bin)"},
            {nil, "libdir",     "kv", nil   , "Set install libraries directory in INSTALLDIR/DIR. (default: ${installdir}/lib)"},
            {nil, "includedir", "kv", nil   , "Set install includes directory in INSTALLDIR/DIR. (default: ${installdir}/include)"},
            {'g', "group",      "kv",  nil  , "Install all targets of the given group. It support path pattern matching.",
                                              "e.g.",
                                              "    xmake install -g test",
                                              "    xmake install -g test_*",
                                              "    xmake install --group=benchmark/*"     },
            {'a', "all",        "k",  nil   , "Install all targets."                      },
            {nil, "binaries",   "kv", true  , "Enable or disable install binary files."   },
            {nil, "headers",    "kv", true  , "Enable or disable install header files."   },
            {nil, "libraries",  "kv", true  , "Enable or disable install library files."  },
            {nil, "packages",   "kv", true  , "Enable or disable install package files."  },
            {},
            {nil, "admin",      "k",  nil   , "Try to request administrator permission to install"},
            {},
            {nil, "target",     "v",  nil   , "The target name. It will install all default targets if this parameter is not specified.",
                                              values = function (complete, opt)
                                                  return import("private.utils.complete_helper.targets")(complete, opt)
                                              end}
        }
    }

