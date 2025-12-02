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
-- @file        syntax_only.lua
--

-- imports
import("core.project.project")

-- add syntax-only check support
-- @see https://github.com/mesonbuild/meson/issues/12228
function main(target, sourcekind)
    -- check if syntax-only is enabled
    local enabled = target:policy("build.c++.syntax_only")
    if enabled == nil then
        enabled = project.policy("build.c++.syntax_only")
    end
    if not enabled then
        return
    end

    -- get flag name for sourcekind
    local flagnames = {
        cc = "cflags",
        cxx = "cxxflags",
        mm = "mflags",
        mxx = "mxxflags"
    }
    local cflag = flagnames[sourcekind] or (sourcekind == "cxx" and "cxxflags" or "cflags")

    -- check compiler and add appropriate flag
    local toolname = sourcekind == "cxx" and "cxx" or "cc"
    if target:has_tool(toolname, "gcc", "gxx", "clang", "clangxx") then
        -- gcc/clang: -fsyntax-only
        target:add(cflag, "-fsyntax-only", {force = true})
    elseif target:has_tool(toolname, "cl") then
        -- MSVC: /Zs (syntax check only)
        target:add(cflag, "/Zs", {force = true})
    end
end

