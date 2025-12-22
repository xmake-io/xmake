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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("private.utils.toolchain", {alias = "toolchain_utils"})

function _load_windows(toolchain, suffix)

    -- add vs environments
    toolchain_utils.add_vsenvs(toolchain)

    if is_host("linux") or project.policy("build.optimization.lto") then
        toolchain:add("ldflags", "-fuse-ld=lld-link" .. suffix)
        toolchain:add("shflags", "-fuse-ld=lld-link" .. suffix)
    end
end

function main(toolchain, suffix)

    -- init tools for lto
    if project.policy("build.optimization.lto") then
        toolchain:set("toolset", "ar",  "llvm-ar" .. suffix)
        toolchain:set("toolset", "ranlib",  "llvm-ranlib" .. suffix)
    end

    -- add target flags
    local flags = toolchain_utils.get_clang_target_flags(toolchain)
    if flags then
        toolchain:add("cxflags", flags)
        toolchain:add("mxflags", flags)
        toolchain:add("asflags", flags)
        toolchain:add("ldflags", flags)
        toolchain:add("shflags", flags)
    end

    -- init windows
    if toolchain:is_plat("windows") then
        _load_windows(toolchain, suffix)
    end

    -- set llvm runtimes
    toolchain_utils.set_llvm_runtimes(toolchain)

    -- add llvm runenvs
    toolchain_utils.add_llvm_runenvs(toolchain)
end
