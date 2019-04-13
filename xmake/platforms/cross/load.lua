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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main(platform)

    -- init linkdirs and includedirs
    local sdkdir = config.get("sdk") 
    if sdkdir then
        local includedir = path.join(sdkdir, "include")
        if os.isdir(includedir) then
            platform:add("includedirs", includedir)
        end
        local linkdir = path.join(sdkdir, "lib")
        if os.isdir(linkdir) then
            platform:add("linkdirs", linkdir)
        end
    end

    -- add bin search library for loading some dependent .dll files windows 
    local bindir = config.get("bin")
    if bindir and is_host("windows") then
        os.addenv("PATH", bindir)
    end
end

