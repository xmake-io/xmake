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

task("watch")
    set_category("plugin")
    on_run("main")
    set_menu {
                usage = "xmake watch [options] [arguments]"
            ,   description = "Watch the project directories and run command."
            ,   options =
                {
                    {'c', "commands"    , "kv"  , nil   ,   "Run the multiple commands instead of the default build command.",
                                                            "e.g.",
                                                            "    $ xmake watch -c 'xmake -rv'",
                                                            "    $ xmake watch -c 'xmake -vD; xmake run hello'"},
                    {'s', "script"      , "kv"  , nil   ,   "Run the given lua script file.",
                                                            "e.g.",
                                                            "    $ xmake watch -s /tmp/watch.lua"},
                    {'d', "watchdirs"   , "kv"  , nil   ,   "Set the given recursive watch directories, the project directories will be watched by default.",
                                                            "e.g.",
                                                            "    $ xmake watch -d src",
                                                            "    $ xmake watch -d 'src/*" .. path.envsep() .. "tests/**/subdir'"},
                    {'p', "plaindirs"   , "kv"  , nil   ,   "Set the given non-recursive watch directories, the project directories will be watched by default.",
                                                            "e.g.",
                                                            "    $ xmake watch -p src",
                                                            "    $ xmake watch -p 'src/*" .. path.envsep() .. "tests/**/subdir'"},
                    {'r', "run"         , "k"   , nil   ,   "Build and run target."},
                    {'t', "target"      , "kv"  , nil   ,   "Build the given target.",
                                                            values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end },
                    {'-', "arbitrary"   , "vs"   , nil  ,   "Run an arbitrary command.",
                                                            "e.g.",
                                                            "    $ xmake watch -- echo hello xmake!",
                                                            "    $ xmake watch -- xmake run",
                                                            "    $ xmake watch -- xmake -rv"}
                }
            }



