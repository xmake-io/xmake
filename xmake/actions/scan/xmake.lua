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
-- @author      ruki, Arthapz
-- @file        xmake.lua
--

task("scan")
    set_category("action")
    on_run("main")
    set_menu {
          usage = "xmake scan|s [options]"
      ,   description = "Scan the project."
      ,   shortname = 's'
      ,   options = 
          {
                {nil, "version",   "k",  nil   , "Print the version number and exit."                            }
            ,   {'s', "scan",      "k",  nil   , "Scan targets. This is default scanning mode and optional."     }
            ,   {'r', "rescan",    "k",  nil   , "Rescan targets."                          }
            ,   {'j', "jobs",      "kv", nil,    "Set the number of parallel scan jobs."                         }
      }
    }

