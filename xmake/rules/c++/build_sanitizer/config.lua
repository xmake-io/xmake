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
import("lib.detect.find_tool")
import("core.base.semver")

-- add build sanitizer
function _add_build_sanitizer(target, sourcekind, checkmode)

    -- add cflags
    local _, cc = target:tool(sourcekind)
    local flagnames = {
        cc = "cflags",
        cxx = "cxxflags",
        mm = "mflags",
        mxx = "mxflags"
    }
    local flagname = flagnames[sourcekind]
    if flagname and target:has_tool(sourcekind, "cl", "clang", "clangxx", "gcc", "gxx") then
        target:add(flagname, "-fsanitize=" .. checkmode)
    end

    -- add ldflags and shflags
    if target:has_tool("ld", "link", "clang", "clangxx", "gcc", "gxx") then
        target:add("ldflags", "-fsanitize=" .. checkmode)
        target:add("shflags", "-fsanitize=" .. checkmode)
    end

end

function main(target, sourcekind)
    local sanitizer = false
    for _, checkmode in ipairs({"address", "thread", "memory", "leak", "undefined"}) do
        local enabled = target:policy("build.sanitizer." .. checkmode)
        if enabled == nil then
            enabled = project.policy("build.sanitizer." .. checkmode)
        end
        if enabled then
            _add_build_sanitizer(target, sourcekind, checkmode)
            sanitizer = true
        end
    end

    if sanitizer then

        -- enable the debug symbols for sanitizer
        if not target:get("symbols") then
            target:set("symbols", "debug")
        end

        -- we need to load runenvs for msvc
        -- @see https://github.com/xmake-io/xmake/issues/4176
        if target:is_plat("windows") and target:is_binary() then
            local msvc = target:toolchain("msvc")
            if msvc then
                local envs = msvc:runenvs()
                local vscmd_ver = envs and envs.VSCMD_VER
                if vscmd_ver and semver.match(vscmd_ver):ge("17.7") then
                    local cl = assert(find_tool("cl", {envs = envs}), "cl not found!")
                    target:add("runenvs", "PATH", path.directory(cl.program))
                end
            end
        end
    end
end
