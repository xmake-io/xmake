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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- main entry
function main(toolchain)

    -- set toolset
    toolchain:set("toolset", "cc",      "clang-cl")
    toolchain:set("toolset", "cxx",     "clang-cl")
    toolchain:set("toolset", "mrc",     "rc.exe")
    toolchain:set("toolset", "dlltool", "llvm-dlltool")
    if toolchain:is_arch("x64") then
        toolchain:set("toolset", "as",  "ml64.exe")
    else
        toolchain:set("toolset", "as",  "ml.exe")
    end
    if project.policy("build.optimization.lto") then
        toolchain:set("toolset", "ld",  "lld-link")
        toolchain:set("toolset", "sh",  "lld-link")
        toolchain:set("toolset", "ar",  "llvm-ar")
    else
        toolchain:set("toolset", "ld",  "link.exe")
        toolchain:set("toolset", "sh",  "link.exe")
        toolchain:set("toolset", "ar",  "link.exe")
    end

    -- add vs environments
    toolchain_utils.add_vsenvs(toolchain)

    local flags = toolchain_utils.get_clang_target_flags(toolchain)
    if flags then
        toolchain:add("cxflags", flags)
        toolchain:add("mxflags", flags)
    end
end

