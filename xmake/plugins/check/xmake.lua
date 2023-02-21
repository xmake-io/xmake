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

task("check")
    set_category("plugin")
    on_run("main")
    set_menu {
        usage = "xmake check [options] [arguments]",
        description = "Check the project sourcecode and configuration.",
        options = {
            {'l', "list",      "k",  nil,   "Show all supported checkers list."},
            {nil, "info",      "kv", nil,   "Show the given checker information."},
            {nil, "checkers",  "v",  "api", "Use the given checkers to check project.",
                                            "e.g.",
                                            "    - xmake check api",
                                            "    - xmake check -v api.target",
                                            "    - xmake check api.target.languages",
                                            "",
                                            "The supported checkers list:",
                values = function (complete, opt)
                    return import("private.check.checker").complete(complete, opt)
                end},
            {nil, "arguments", "vs", nil,   "Set the checker arguments.",
                                            "e.g.",
                                            "    - xmake check clang.tidy [arguments]"}
        }
    }

