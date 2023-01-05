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

-- define task
task("lua")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake lua|l [options] [script] [arguments]"

                -- description
            ,   description = "Run the lua script."

                -- xmake l
            ,   shortname = 'l'

                -- options
            ,   options =
                {

                    {'l', "list"        , "k"   , nil   ,   "List all scripts."                                             }
                ,   {'c', "command"     , "k"   , nil   ,   "Run script as command"                                         }
                ,   {'d', "deserialize" , "kv"  , nil   ,   "Deserialize arguments starts with given prefix"                }
                ,   {nil, "script"      , "v"   , nil   ,   "Run the given lua script name, file or module and enter interactive mode if no given script.",
                                                            "e.g.",
                                                            "    - xmake lua (enter interactive mode)",
                                                            "    - xmake lua /tmp/script.lua",
                                                            "    - xmake lua echo 'hello xmake'",
                                                            "    - xmake lua core.xxx.xxx",
                                                            "    - xmake lua -c 'print(...)' hello xmake!"
                                                        ,   values = function (complete, opt)
                                                                if not complete or opt.command or opt.list then
                                                                    return
                                                                end
                                                                local list = import("main.scripts")()
                                                                if list and complete then
                                                                    local result = {}
                                                                    for _, item in ipairs(list) do
                                                                        if item:startswith(complete) then
                                                                            table.insert(result, item)
                                                                        end
                                                                    end
                                                                    if #result > 0 then
                                                                        return result
                                                                    end
                                                                end
                                                                -- we just return nil and fallback to system autocomplete
                                                                -- it will complete file path, e.g. `xmake l scripts/test.lua`
                                                            end                                                             }
                ,   {nil, "arguments"   ,  "vs" , nil   ,   "The script arguments, use '--deserialize' option to enable deserializing.",
                                                            "e.g.",
                                                            "    - xmake lua -d@ lib.detect.find_tool tar @{version=true}"      }
                }
            }



