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
-- @file        show_logs.lua
--

-- imports
import("core.base.option")
import("private.service.server_config", {alias = "config"})

function main()
    local log
    local logfile = config.get("logfile")
    while not log do
        if os.isfile(logfile) then
            log = io.open(logfile, "r")
            break
        end
        os.sleep(1000)
    end
    while true do
        local line = log:read("l")
        if line and #line > 0 then
            print(line)
        else
            os.sleep(500)
        end
    end
end

