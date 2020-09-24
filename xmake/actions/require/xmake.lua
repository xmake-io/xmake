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
-- @file        require.lua
--

-- define task
task("require")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake require [options] [packages]"

                -- description
            ,   description = "Install and update required packages."

                -- xmake q
            ,   shortname = 'q'

                -- options
            ,   options =
                {
                    {'c', "clean",      "k",  nil,       "Clear all package caches and uninstall all not-referenced packages.",
                                                         "e.g.",
                                                         "    $ xmake require --clean",
                                                         "    $ xmake require --clean zlib tbox pcr*"                          }
                ,   {'f', "force",      "k",  nil,       "Force to reinstall all package dependencies."                        }
                ,   {nil, "shallow",    "k",  nil,       "Only install the root packages."                                     }
                ,   {'l', "list",       "k",  nil,       "List all package dependencies in project.",
                                                         "e.g.",
                                                         "    $ xmake require --list"                                          }
                ,   {nil, "scan",       "k",  nil,       "Scan the given or all installed packages.",
                                                         "e.g.",
                                                         "    $ xmake require --scan",
                                                         "    $ xmake require --scan zlib tbox pcr*"                           }
                ,   {                                                                                                          }
                ,   {nil, "info",       "k",  nil,       "Show the given package info.",
                                                         "e.g.",
                                                         "    $ xmake require --info tbox"                                     }
                ,   {'s', "search",     "k",  nil,       "Search for the given packages from repositories.",
                                                         "e.g.",
                                                         "    $ xmake require --search tbox"                                   }
                ,   {nil, "uninstall",  "k",  nil,       "Uninstall the installed packages.",
                                                         "e.g.",
                                                         "    $ xmake require --uninstall",
                                                         "    $ xmake require --uninstall tbox",
                                                         "    $ xmake require --uninstall --extra=\"{debug=true}\" tbox"       }
                ,   {nil, "export",     "k", nil,        "Export the installed packages and their dependencies.",
                                                         "e.g.",
                                                         "    $ xmake require --export",
                                                         "    $ xmake require --export tbox zlib",
                                                         "    $ xmake require --export --exportdir=packagesdir zlib",
                                                         "    $ xmake require --export --extra=\"{debug=true}\" tbox"          }
                ,   {nil, "exportdir",  "kv", "packages","Set the exported packages directory."                                }
                ,   {nil, "extra",      "kv", nil,       "Set the extra info of packages."                                     }
                ,   {                                                                                                          }
                ,   {nil, "requires",   "vs", nil,       "The package requires.",
                                                         "e.g.",
                                                         "    $ xmake require zlib tbox",
                                                         "    $ xmake require \"zlib >=1.2.11\" \"tbox master\"",
                                                         "    $ xmake require --extra=\"{debug=true,configs={xxx=true}}\" tbox"}
                }
            }
