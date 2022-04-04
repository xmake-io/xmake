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
    set_category("plugin")
    on_run("main")

    set_menu {usage = "xmake service [options]",
              description = "Start service for remote or distributed compilation and etc. ${color.warning}(Experimental, still in development)",
              options = {
                {nil, "start",   "k",  nil, "Start daemon service."                                       },
                {nil, "restart", "k",  nil, "Restart daemon service."                                     },
                {nil, "stop" ,   "k",  nil, "Stop daemon service."                                        },
                {nil, "logs",    "k",  nil, "Show service logs if the daemon service has been started."   },
                {nil, "status",  "k",  nil, "Show service status if the daemon service has been started." }
             }}
