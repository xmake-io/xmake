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
-- @file        macro.lua
--

-- define task
task("macro")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake macro|m [options] [name] [arguments]"

                -- description
            ,   description = "Run the given macro."

                -- xmake m
            ,   shortname = 'm'

                -- options
            ,   options =
                {
                    {'b', "begin",      "k",  nil,  "Start to record macro."
                                                ,   "e.g."
                                                ,   "Record macro with name: test"
                                                ,   "    xmake macro --begin"
                                                ,   "    xmake config --plat=macosx"
                                                ,   "    xmake clean"
                                                ,   "    xmake -r"
                                                ,   "    xmake package"
                                                ,   "    xmake macro --end test"                    }
                ,   {'e', "end",        "k",  nil,  "Stop to record macro."                         }
                ,   {}
                ,   {nil, "show",       "k",  nil,  "Show the content of the given macro."          }
                ,   {'l', "list",       "k",  nil,  "List all macros."                              }
                ,   {'d', "delete",     "k",  nil,  "Delete the given macro."                       }
                ,   {'c', "clear",      "k",  nil,  "Clear the all macros."                         }
                ,   {}
                ,   {nil, "import",     "kv", nil,  "Import the given macro file or directory."
                                                ,   "e.g."
                                                ,   "    xmake macro --import=/xxx/macro.lua test"
                                                ,   "    xmake macro --import=/xxx/macrodir"        }
                ,   {nil, "export",     "kv", nil,  "Export the given macro to file or directory."
                                                ,   "e.g."
                                                ,   "    xmake macro --export=/xxx/macro.lua test"
                                                ,   "    xmake macro --export=/xxx/macrodir"        }
                ,   {}
                ,   {nil, "name",       "v",  ".",  "Set the macro name."
                                                ,   "e.g."
                                                ,   "   Run the given macro:     xmake macro test"
                                                ,   "   Run the anonymous macro: xmake macro ."
                                                ,   "   Run the last command:    xmake macro .."
                                                ,   values = function (complete, opt)
                                                        -- hide in help menu
                                                        if not complete then return end
                                                        -- don't need name
                                                        if opt.begin or opt.list or opt.clear then return end
                                                        -- name should be given by user
                                                        if opt["end"] or opt.import then return end

                                                        return import("main.macros")(".")
                                                    end                                             }
                ,   {nil, "arguments",  "vs", nil,  "Set the macro arguments."                      }
                }
            }
