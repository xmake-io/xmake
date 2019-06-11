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
    local arch = config.get("arch") or os.arch()

    -- init flags for asm
    platform:add("yasm.asflags", "-f", arch == "x64" and "win64" or "win32")

    -- init flags for dlang
    local dc_archs = { x86 = "-m32", x64 = "-m64" }
    platform:add("dcflags", dc_archs[arch])
    platform:add("dc-shflags", dc_archs[arch])
    platform:add("dc-ldflags", dc_archs[arch])
end
