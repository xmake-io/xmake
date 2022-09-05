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
-- @file        xmake.lua
--

-- @see https://github.com/xmake-io/xmake/issues/1896
rule("python.library")
    on_config(function (target)
        target:set("kind", "shared")
        target:set("prefixname", "")
        target:add("runenvs", "PYTHONPATH", target:targetdir())
        local soabi = target:extraconf("rules", "python.library", "soabi")
        if soabi then
            import("lib.detect.find_tool")
            local python = assert(find_tool("python3"), "python not found!")
            local result = try { function() return os.iorunv(python.program, {"-c", "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"}) end}
            if result then
                result = result:trim()
                if result ~= "None" then
                    target:set("extension", result)
                end
            end
        else
            if target:is_plat("windows", "mingw") then
                target:set("extension", ".pyd")
            else
                target:set("extension", ".so")
            end
        end
        -- fix segmentation fault for macosx
        -- @see https://github.com/xmake-io/xmake/issues/2177#issuecomment-1209398292
        if target:is_plat("macosx", "linux") then
            if target:is_plat("macosx") then
                target:add("shflags", "-undefined dynamic_lookup", {force = true})
            end
            for _, pkg in pairs(target:pkgs()) do
                local links = pkg:get("links")
                if links then
                    local with_python = false
                    for _, link in ipairs(links) do
                        if link:startswith("python") then
                            with_python = true
                            break
                        end
                    end
                    if with_python then
                        pkg:set("links", nil)
                        pkg:set("linkdirs", nil)
                    end
                end
            end
        end
    end)
