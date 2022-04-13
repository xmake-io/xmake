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
-- @file        xmake.lua
--

task("clean")
    set_category("action")
    on_run("main")

    set_menu {
                usage = "xmake clean|c [options] [target]"
            ,   description = "Remove all binary and temporary files."
            ,   shortname = 'c'

            ,   options =
                {
                    {'a', "all",        "k",  nil   , "Clean all auto-generated files by xmake."                      }

                ,   {}
                ,   {nil, "target",     "v",  nil   , "The target name. It will clean all default targets if this parameter is not specified."
                                                    , values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end }
                }
            }



