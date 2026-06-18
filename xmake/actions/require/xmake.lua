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
-- @file        require.lua
--

task("require")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake require [options] [packages]",
        description = "Install and update required packages.",
        shortname = 'q',
        options = {
            {'c', "clean",       "k",  nil,        "Clear all package caches and uninstall all not-referenced packages.",
                                                   "e.g.",
                                                   "    $ xmake require --clean",
                                                   "    $ xmake require --clean zlib tbox pcr*"},
            {nil, "clean_modes", "kv", nil,        "Set the modes of cleaning packages.",
                                                   "e.g.",
                                                   "    $ xmake require --clean --clean_modes=cache,package"},
            {'f', "force",       "k",  nil,        "Force to reinstall all package dependencies."},
            {'j', "jobs",        "kv", tostring(os.default_njob()),
                                                   "Set the number of parallel compilation jobs."},
            {nil, "linkjobs",    "kv", nil,        "Set the number of parallel link jobs."},
            {nil, "shallow",     "k",  nil,        "Does not install or download dependent packages."},
            {nil, "build",       "k",  nil,        "Always build and install packages from source."},
            {'l', "list",        "k",  nil,        "List all package dependencies in project.",
                                                   "e.g.",
                                                   "    $ xmake require --list"},
            {nil, "scan",        "k",  nil,        "Scan the given or all installed packages.",
                                                   "e.g.",
                                                   "    $ xmake require --scan",
                                                   "    $ xmake require --scan zlib tbox pcr*"},
            {},
            {nil, "info",        "k",  nil,        "Show the given package info.",
                                                   "e.g.",
                                                   "    $ xmake require --info tbox"},
            {nil, "depgraph",    "k",  nil,        "Show the dependency graph of the given packages.",
                                                   "e.g.",
                                                   "    $ xmake require --depgraph libpng",
                                                   "    $ xmake require --depgraph --format=json libpng",
                                                   "    $ xmake require --depgraph --format=dot libpng"},
            {nil, "format",      "kv", nil,        "Set the output format.",
                                                   "e.g.",
                                                   "    $ xmake require --info --format=json zlib",
                                                   "    $ xmake require --depgraph --format=dot libpng",
                                                   "values: json (for --info/--depgraph), dot (for --depgraph only)",
                                                   values = {"plain", "json", "dot"}},
            {nil, "check",       "k",  nil,        "Check whether the given package is supported",
                                                   "e.g.",
                                                   "    $ xmake require --check tbox"},
            {nil, "fetch",       "k",  nil,        "Fetch the library info of given package.",
                                                   "e.g.",
                                                   "    $ xmake require --fetch tbox"},
            {nil, "fetch_modes", "kv", nil,        "Set the modes of fetching packages.",
                                                   "e.g.",
                                                   "    $ xmake require --fetch --fetch_modes=cflags,external tbox",
                                                   "    $ xmake require --fetch --fetch_modes=deps,cflags,ldflags tbox"},
            {'s', "search",      "k",  nil,        "Search for the given packages from repositories.",
                                                   "e.g.",
                                                   "    $ xmake require --search tbox"},
            {nil, "upgrade",     "k",  nil,        "Upgrade the installed packages."},
            {nil, "download",    "k",  nil,        "Only download the given package source archive files."},
            {nil, "uninstall",   "k",  nil,        "Uninstall the installed packages.",
                                                   "e.g.",
                                                   "    $ xmake require --uninstall",
                                                   "    $ xmake require --uninstall tbox",
                                                   "    $ xmake require --uninstall --extra=\"{debug=true}\" tbox"},
            {nil, "export",      "k",  nil,        "Export the installed packages and their dependencies.",
                                                   "e.g.",
                                                   "    $ xmake require --export",
                                                   "    $ xmake require --export tbox zlib",
                                                   "    $ xmake require --export --packagedir=packagesdir zlib",
                                                   "    $ xmake require --export --extra=\"{debug=true}\" tbox"},
            {nil, "import",      "k",  nil,        "Import the installed packages and their dependencies.",
                                                   "e.g.",
                                                   "    $ xmake require --import",
                                                   "    $ xmake require --import tbox zlib",
                                                   "    $ xmake require --import --packagedir=packagesdir zlib",
                                                   "    $ xmake require --import --extra=\"{debug=true}\" tbox"},
            {nil, "packagedir",  "kv", "packages", "Set the packages directory for exporting, importing and downloading."},
            {nil, "debugdir",    "kv", nil,        "Set the source directory of the current package for debugging."},
            {nil, "extra",       "kv", nil,        "Set the extra info of packages."},
            {},
            {nil, "requires",    "vs", nil,        "The package requires.",
                                                   "e.g.",
                                                   "    $ xmake require zlib tbox",
                                                   "    $ xmake require \"zlib >=1.2.11\" \"tbox master\"",
                                                   "    $ xmake require --extra=\"{debug=true,configs={xxx=true}}\" tbox"}
        }
    }
