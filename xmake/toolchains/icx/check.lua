--!A cross-toolchain build utility based on Lua
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
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_icxenv")
import("lib.detect.find_tool")

-- main entry
function main(toolchain)
    local icxenv = toolchain:config("icxenv")
    if icxenv then
        return true
    end
    icxenv = find_icxenv()
    if icxenv then
        local tool = find_tool("icx", {force = true, paths = icxenv.bindir})
        if tool then
            cprint("checking for Intel LLVM C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
            toolchain:config_set("icxenv", icxenv)
            toolchain:config_set("bindir", icxenv.bindir)
            toolchain:configs_save()
            return true
        end
        return true
    end
end

