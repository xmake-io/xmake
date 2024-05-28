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
-- @file        pack.lua
--

task("pack")
    set_category("plugin")
    on_run("main")
    set_menu {
        usage = "xmake pack [options] [names]",
        description = "Pack binary installation packages.",
        options = {
            {'o', "outputdir", "kv", nil,   "Set the output directory. (default: build/xpack)"},
            {nil, "basename",  "kv", nil,   "Set the basename of the output file."},
            {nil, "autobuild", "kv", true,  "Build targets automatically."},
            {'j', "jobs",      "kv", tostring(os.default_njob()), "Set the number of parallel compilation jobs."   },
            {'f', "formats",   "kv", "all", "Pack the given package formats.",
                                            "e.g.",
                                            "    - xmake pack -f nsis,deb,rpm",
                                            "values:",
                                            values = {"nsis", "wix", "deb", "srpm", "rpm", "runself", "targz", "zip", "srctargz", "srczip"}},
            {},
            {nil, "packages",  "vs", nil,   "The package names."}
        }
    }
