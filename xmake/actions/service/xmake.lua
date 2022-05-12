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
-- @file        service.lua
--

task("service")
    set_category("action")
    on_run("main")

    set_menu {usage = "xmake service [options]",
              description = "Start service for remote or distributed compilation and etc.",
              options = {
                {nil, "start",      "k",  nil, "Start daemon service.",
                                               "e.g.",
                                               "    - xmake service --start",
                                               "    - xmake service --start --remote",
                                               "    - xmake service --start --distcc",
                                               "    - xmake service --start --remote --distcc"               },
                {nil, "restart",    "k",  nil, "Restart daemon service."                                     },
                {nil, "stop" ,      "k",  nil, "Stop daemon service."                                        },
                {nil, "connect" ,   "k",  nil, "Connect current project to the remote daemon service.",
                                               "e.g.",
                                               "    - xmake service --connect",
                                               "    - xmake service --connect --remote",
                                               "    - xmake service --connect --distcc",
                                               "    - xmake service --connect --remote --distcc"             },
                {nil, "reconnect",  "k",  nil, "Reconnect current project to the remote daemon service."     },
                {nil, "disconnect", "k",  nil, "Disconnect current project in the remote daemon service."    },
                {nil, "remote",     "k",  nil, "Start or connect the remote build service."                  },
                {nil, "distcc",     "k",  nil, "Start or connect the distributed build service."             },
                {nil, "sync",       "k",  nil, "Sync current project files in the remote daemon service."    },
                {nil, "clean",      "k",  nil, "Clean current project files in the remote daemon service."   },
                {nil, "add-user",   "kv", nil, "Add user in the server.",
                                               "e.g.",
                                               "    - xmake service --add-user=root"                         },
                {nil, "rm-user",    "kv", nil, "Remove user in the server.",
                                               "e.g.",
                                               "    - xmake service --rm-user=root"                          },
                {nil, "gen-token",  "k",  nil, "Generate a new token in the server.",
                                               "e.g.",
                                               "    - xmake service --gen-token"                             },
                {nil, "logs",       "k",  nil, "Show service logs if the daemon service has been started."   },
                {nil, "status",     "k",  nil, "Show service status if the daemon service has been started." }
             }}
