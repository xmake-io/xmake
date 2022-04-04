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
-- @file        server.lua
--

-- imports
import("core.base.object")

-- define module
local server = server or object()

-- init server
function server:init()
end

-- get super
function server:super()
    return self._super
end

-- run main loop
function server:runloop()
    while true do
        print("hello xmake!")
        os.sleep(1000)
    end
end

function main()
    local instance = server()
    instance._super = server
    instance:init()
    return instance
end
