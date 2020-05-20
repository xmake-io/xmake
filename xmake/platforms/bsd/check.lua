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
import("private.platform.check_arch")

-- check it
function main(platform)

    -- check arch
    check_arch(config, os.arch())

    -- check toolchains
    local toolchains = platform:toolchains()
    local idx = 1
    local num = #toolchains
    local standalone = false
    while idx <= num do
        local toolchain = toolchains[idx]
        -- we need remove other standalone toolchains if standalone toolchain found
        if (standalone and toolchain:standalone()) or not toolchain:check() then
            table.remove(toolchains, idx)
            num = num - 1
        else
            if toolchain:standalone() then
                standalone = true
            end
            idx = idx + 1
        end
    end
    assert(#toolchains > 0, "toolchains not found!")
end

