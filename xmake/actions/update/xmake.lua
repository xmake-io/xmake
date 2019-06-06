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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define task
task("update")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake update [options] [xmakever]"

                -- description
            ,   description = "Update and uninstall the xmake program."

                -- options
            ,   options = 
                {
                    {nil, "uninstall",   "k",   nil,   "Uninstall the current xmake program."                     }
                ,   {                                                                                             }
                ,   {'s', "scriptonly",  "k",   nil,   "Update script only"                                       }
                ,   {nil, "xmakever",    "v",   nil,   "The given xmake version, or a git source (and branch). ",
                                                       "e.g.",
                                                       "    from official source: ",
                                                       "        lastest, ~2.2.3, dev, master", 
                                                       "    from custom source:", 
                                                       "        https://github.com/xmake-io/xmake", 
                                                       "        github:xmake-io/xmake#~2.2.3",
                                                       "        git://github.com/xmake-io/xmake.git#master"       }
                }
            }



