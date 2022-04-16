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
-- @file        environment.lua
--

-- imports
import("lib.detect.find_tool")

-- check environment
--
-- ensure that we can find some basic tools: zip, 7zip, ...
--
-- If these tools not exist, we will install it first.
--
function check(server_side)
    if server_side then
        -- unzip or 7zip is necessary
        if not find_tool("unzip") and not find_tool("7z") then
            raise("unzip or 7zip not found! we need install it first")
        end
    else
        -- zip or 7zip is necessary
        if not find_tool("zip") and not find_tool("7z") then
            raise("zip or 7zip not found! we need install it first")
        end
    end
end
