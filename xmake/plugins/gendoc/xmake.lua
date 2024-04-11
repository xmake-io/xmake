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
-- @author      charlesseizilles
-- @file        gendoc.lua
--

task("gendoc")
    set_category("plugin")
    on_run("main")
    set_menu {
                usage = "xmake gendoc [options]",
                description = "Generate the API documentation.",
                options = {
                    {'o', "output",  "kv", nil,   "Output html directory. (default is $\xA0(buildir)/doc/html)"},
                    {'s', "siteroot","kv", nil,   "Site root. (default is https://xmake.io)"},
                }
            }
