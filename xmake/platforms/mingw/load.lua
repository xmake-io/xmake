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

    -- init flags for architecture
    local archflags = nil
    local arch = config.get("arch")
    if arch then
        if arch == "x86_64" then archflags = "-m64"
        elseif arch == "i386" then archflags = "-m32"
        else archflags = "-arch " .. arch
        end
    end
    if archflags then
        platform:add("cxflags", archflags)
        platform:add("asflags", archflags)
        platform:add("ldflags", archflags)
        platform:add("shflags", archflags)
    end

    -- init flags for asm
    platform:add("yasm.asflags", "-f", arch == "x86_64" and "win64" or "win32")

    -- add bin search library for loading some dependent .dll files windows 
    local bindir = config.get("bin")
    if bindir and is_host("windows") then
        os.addenv("PATH", bindir)
    end
end

