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
task("project")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake project [options] [target]"

                -- description
            ,   description = "Generate the project file."

                -- options
            ,   options =
                {
                    {'k', "kind",      "kv" , "makefile",   "Set the project kind."
                                                        ,   "    - make"
                                                        ,   "    - xmakefile (makefile with xmake)"
                                                        ,   "    - cmake"
                                                        ,   "    - ninja"
                                                        ,   "    - xcode (need cmake)"
                                                        ,   "    - compile_flags"
                                                        ,   "    - compile_commands (clang compilation database with json format)"
                                                        ,   "    - vs (auto detect), vs2002, vs2003, vs2005, vs2008"
                                                        ,   "    - vs2010, vs2012, vs2013, vs2015, vs2017, vs2019"
                                                        ,   "    - vsxmake (auto detect), vsxmake2010 ~ vsxmake2019"
                                                        ,   values = function (complete, opt)
                                                                if not complete then return end

                                                                local values = table.keys(import("main.makers")())
                                                                table.sort(values, function (a, b) return a > b end)
                                                                return values
                                                            end                                                                             }
                ,   {'m', "modes",     "kv" , nil       ,   "Set the project modes."
                                                        ,   "    e.g. "
                                                        ,   "    - xmake project -k vsxmake -m \"release" .. path.envsep() ..  "debug\""    }
                ,   {'a', "archs",     "kv" , nil       ,          "Set the project archs."
                                                        ,   "    e.g. "
                                                        ,   "    - xmake project -k vsxmake -a \"x86" .. path.envsep() ..  "x64\""          }
                ,   {nil, "outputdir", "v"  , "."       ,   "Set the output directory."                                                     }
                }
            }



