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
-- @file        plugin.lua
--

-- define task
task("plugin")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {

        -- usage
        usage = "xmake plugin [options]"

        -- description
    ,   description = "Manage plugins of xmake."

        -- options
    ,   options =
        {
            {'i', "install", "k",  nil,      "Install all plugins of the official remote repository." }
        ,   {'c', "clear",  "k",  nil,       "Clear all installed plugins."                           }
        }
    }
