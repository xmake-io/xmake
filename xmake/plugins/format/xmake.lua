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
-- @file        format.lua
--

task("format")
    set_category("plugin")
    on_run("main")
    set_menu {
                usage = "xmake format [options] [arguments]",
                description = "Format the current project.",
                options = {
                    {'s', "style",   "kv",  nil,  "Set the path of .clang-format file, a coding style",
                                                  values = {"LLVM", "Google", "Chromium", "Mozilla", "WebKit"}},
                    {nil, "create",  "k",  nil,   "Create a .clang-format file from a coding style"},
                    {'n', "dry-run", "k",  nil,   "Do not make any changes, just show the files that would be formatted."},
                    {'e', "error",   "k",  nil,   "If set, changes formatting warnings to errors."},
                    {'a', "all",     "k",  nil,   "Format all targets."},
                    {'g', "group",   "kv", nil,   "Format all targets of the given group. It support path pattern matching.",
                                                  "e.g.",
                                                  "    xmake format -g test",
                                                  "    xmake format -g test_*",
                                                  "    xmake format --group=benchmark/*"},
                    {'f', "files",   "kv", nil,   "Build the given source files.",
                                                  "e.g.",
                                                  "    - xmake format --files=src/main.c",
                                                  "    - xmake format --files='src/*.c' [target]",
                                                  "    - xmake format --files='src/**.c|excluded_file.c",
                                                  "    - xmake format --files='src/main.c" .. path.envsep() .. "src/test.c'" },
                                                  {},
                    {nil, "target",  "v",  nil,   "The target name. It will format all default targets if this parameter is not specified."
                                                       , values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end }
                }
            }



