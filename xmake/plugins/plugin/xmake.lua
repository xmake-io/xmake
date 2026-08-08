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
-- @file        plugin.lua
--

task("plugin")
    set_category("plugin")
    on_run("main")
    set_menu {
        usage = "xmake plugin [options]",
        description = "Manage plugins of xmake. (deprecated, please use `xmake addon` instead)",
        options = {
            {'i', "install", "k", nil, "Install plugins."},
            {'r', "remove",  "k", nil, "Remove the given installed plugin."},
            {'l', "list",    "k", nil, "List all installed plugins."},
            {'c', "clear",   "k", nil, "Clear all installed plugins."},
            {nil, "plugins", "vs", nil, "The plugin paths, urls or names.",
                                       "e.g.",
                                       "    $ xmake plugin --install https://github.com/myrepo/hello-world",
                                       "    $ xmake plugin --install github:myrepo/hello-world",
                                       "    $ xmake plugin --install github:myrepo/hello-world#dev",
                                       "    $ xmake plugin --install /tmp/my-plugin",
                                       "    $ xmake plugin --install xmake-repo@hello-world",
                                       "    $ xmake plugin --install hello-world",
                                       "    $ xmake plugin --remove hello-world",
                                       "    $ xmake plugin --list"}
        }
    }
