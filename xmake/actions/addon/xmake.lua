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

task("addon")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake addon [options]",
        description = "Manage addons of xmake.",
        options = {
            {'i', "install", "k", nil, "Install addons."},
            {'r', "remove",  "k", nil, "Remove the given installed addons."},
            {'s', "search",  "k", nil, "Search the addons from the repositories."},
            {'l', "list",    "k", nil, "List all installed addons."},
            {'u', "upgrade", "k", nil, "Upgrade the addons which the current project declares."},
            {nil, "all",     "k", nil, "Remove all installed addons, e.g. xmake addon --remove --all"},
            {'f', "force",   "k", nil, "Force to remove the addons, even if they are depended on by the others."},
            {nil, "addons",  "vs", nil, "The addon paths, urls or names.",
                                       "e.g.",
                                       "    $ xmake addon --install https://github.com/myrepo/serial-monitor",
                                       "    $ xmake addon --install github:myrepo/serial-monitor",
                                       "    $ xmake addon --install github:myrepo/serial-monitor#dev",
                                       "    $ xmake addon --install /tmp/my-addon",
                                       "    $ xmake addon --install xmake-repo@serial-monitor",
                                       "    $ xmake addon --install serial-monitor",
                                       "    $ xmake addon --remove serial-monitor",
                                       "    $ xmake addon --remove --all",
                                       "    $ xmake addon --upgrade",
                                       "    $ xmake addon --search serial",
                                       "    $ xmake addon --list"}
        }
    }
