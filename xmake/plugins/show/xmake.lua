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
-- @file        xmake.lua
--

-- define task
task("show")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake show [options] [arguments]"

                -- description
            ,   description = "Show the given project information."

                -- options
            ,   options =
                {
                    {'l', "list"        , "kv"  , nil   ,   "Show the values list of the given name."
                                                        ,   values = function (complete, opt)
                                                                return import("list").lists()
                                                            end},
                    {'t', "target"      , "kv"  , nil   ,   "Show the information of the given target."
                                                        ,   values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end }
                }
            }



