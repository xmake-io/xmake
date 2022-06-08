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
-- @file        plugin.lua
--

task("plugin")
    set_category("plugin")
    on_run("main")
    set_menu {
        usage = "xmake plugin [options]",
        description = "Manage plugins of xmake.",
        options = {
            {'i', "install", "k",  nil,      "Install plugins."             },
            {'u', "update",  "k",  nil,      "Update plugins."              },
            {'c', "clear",   "k",  nil,      "Clear all installed plugins." },
            {nil, "plugins", "v",  nil,      "The plugins path or url.",
                                             "e.g.",
                                             "    $ xmake plugin --install https://github.com/xmake-io/xmake-plugins",
                                             "    $ xmake plugin --update"}
        }
    }
