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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.project.config")

-- check the architecture
function _check_arch()

    -- get the architecture
    local arch = config.get("arch")
    if not arch then
        config.set("arch", "none")
    end
end

-- check it
function main(platform)

    -- check arch
    _check_arch()

    -- check toolchains
    local toolchains = platform:toolchains()
    for idx, toolchain in irpairs(toolchains) do
        if not toolchain:check() then
            table.remove(toolchains, idx)
        end
    end
    assert(#toolchains > 0, "toolchains not found!")
end

