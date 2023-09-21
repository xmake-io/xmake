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

-- add build sanitizer
function _add_build_sanitizer(target, sourcekind, checkmode)

    -- add cflags
    local _, cc = target:tool(sourcekind)
    local cflag = sourcekind == "cxx" and "cxxflags" or "cflags"
    if target:has_tool(sourcekind, "cl", "clang", "clangxx", "gcc", "gxx") then
        target:add(cflag, "-fsanitize=" .. checkmode)
    end

    -- add ldflags and shflags
    if target:has_tool("ld", "link", "clang", "clangxx", "gcc", "gxx") then
        target:add("ldflags", "-fsanitize=" .. checkmode)
        target:add("shflags", "-fsanitize=" .. checkmode)
    end
end

function main(target, sourcekind)
    if target:policy("build.sanitizer.address") or
        project.policy("build.sanitizer.address") then
        _add_build_sanitizer(target, sourcekind, "address")
    end
end
