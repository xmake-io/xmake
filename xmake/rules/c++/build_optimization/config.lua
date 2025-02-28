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
function _add_lto_optimization(target, sourcekind)

    -- add cflags
    local _, cc = target:tool(sourcekind)
    local cflag = sourcekind == "cxx" and "cxxflags" or "cflags"
    if cc == "cl" then
        target:add(cflag, "-GL")
    elseif cc == "clang" or cc == "clangxx" or cc == "clang_cl" then
        target:add(cflag, "-flto=thin")
    elseif cc == "gcc" or cc == "gxx" then
        target:add(cflag, "-flto")
    end

    -- add ldflags and shflags
    local program, ld = target:tool("ld")
    if ld == "link" then
        target:add("ldflags", "-LTCG")
        target:add("shflags", "-LTCG")
    elseif ld == "clang" or ld == "clangxx" then
        target:add("ldflags", "-flto=thin")
        target:add("shflags", "-flto=thin")
    elseif ld == "gcc" or ld == "gxx" then
        target:add("ldflags", "-flto")
        target:add("shflags", "-flto")

        -- to use the link-time optimizer, -flto and optimization options should be specified at compile time and during the final link.
        -- @see https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
        local optimize = target:get("optimize")
        if optimize then
            local optimize_flags = compiler.map_flags(sourcekind == "cc" and "c" or "cxx", "optimize", optimize)
            target:add("ldflags", optimize_flags)
            target:add("shflags", optimize_flags)
        end
    end

    local program, ar = target:tool("ar")
    if cc == "clang_cl" then
        if ld == "link" then
            wprint([[Unsupported toolset(%s) for lto, please use `set_toolset("ld", "lld-link")`]], ld)
            target:set("toolset", "ld", "lld-link")
            target:set("toolset", "sh", "lld-link")
        end
        if ar ~= "llvm-ar" and ar ~= "llvm_ar" then
            wprint([[Unsupported toolset(%s) for lto, please use `set_toolset("ar", "llvm-ar")`]], ar)
            target:set("toolset", "ar", "llvm-ar")
        end
    end
end

function main(target, sourcekind)
    if target:policy("build.optimization.lto") or
        project.policy("build.optimization.lto") then
        _add_lto_optimization(target, sourcekind)
    end
end
