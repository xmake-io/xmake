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
                                                        ,   "    - vs (auto detect), vs2002 - vs2022"
                                                        ,   "    - vsxmake (auto detect), vsxmake2010 ~ vsxmake2022"
                                                        ,   values = function (complete, opt)
                                                                if not complete then return end

                                                                local values = table.keys(import("main.makers")())
                                                                table.sort(values, function (a, b) return a > b end)
                                                                return values
                                                            end                                                                             }
                ,   {'m', "modes",     "kv" , nil       ,   "Set the project modes."
                                                        ,   "    e.g. "
                                                        ,   "    - xmake project -k vsxmake -m \"release,debug\""                           }
                ,   {'a', "archs",     "kv" , nil       ,   "Set the project archs."
                                                        ,   "    e.g. "
                                                        ,   "    - xmake project -k vsxmake -a \"x86,x64\""                                 }
                ,   {nil, "lsp",       "kv" , nil       ,   "Set the LSP backend for compile_commands."
                                                        ,   "    e.g. "
                                                        ,   "    - xmake project -k compile_commands --lsp=clangd"
                                                        ,   values = {"clangd", "cpptools", "ccls"}}
                ,   {nil, "outputdir", "v"  , "."       ,   "Set the output directory."                                                     }
                }
            }



