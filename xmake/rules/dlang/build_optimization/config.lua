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
-- @file        config.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")

-- add lto optimization
function _add_lto_optimization(target)
    if target:has_tool("dc", "ldc2") and target:has_tool("dcld", "ldc2") then
        target:add("dcflags", "-flto=thin", {force = true})
        target:add("ldflags", "-flto=thin", "-defaultlib=phobos2-ldc-lto,druntime-ldc-lto", {force = true})
        target:add("shflags", "-flto=thin", "-defaultlib=phobos2-ldc-lto,druntime-ldc-lto", {force = true})
        -- to use the link-time optimizer, lto and optimization options should be specified at compile time and during the final link.
        -- @see https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
        local optimize = target:get("optimize")
        if optimize then
            local optimize_flags = compiler.map_flags("d", "optimize", optimize)
            target:add("ldflags", optimize_flags)
            target:add("shflags", optimize_flags)
        end
    end
end

function main(target)
    if target:policy("build.optimization.lto") or
        project.policy("build.optimization.lto") then
        _add_lto_optimization(target)
    end
end
