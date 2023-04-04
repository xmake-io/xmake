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
-- @file        shflags.lua
--

-- imports
import("core.tool.compiler")
import(".api_checker")

function main(opt)
    opt = opt or {}
    api_checker.check_targets("shflags", table.join(opt, {check = function(target, value)
        if target:is_shared() then
            local linker = target:linker()
            if not api_checker.check_flag(target, linker, "shflags", value) then
                return false, string.format("%s: unknown linker flag '%s'", linker:name(), value)
            end
        end
        return true
    end}))
end
