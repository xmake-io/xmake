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

-- update vsxmake project automatically
--
-- @code
-- add_rules("plugin.vsxmake.autoupdate")
-- target("test")
--     set_kind("binary")
--     add_files("src/*.c")
-- @endcode
--
rule("plugin.vsxmake.autoupdate")
    set_kind("project")
    after_build(function (opt)

        -- imports
        import("core.project.config")
        import("core.project.depend")
        import("core.project.project")
        import("core.cache.localcache")
        import("core.base.task")

        -- run only once for all xmake process in vs
        local tmpfile = path.join(config.buildir(), ".gens", "rules", "plugin.vsxmake.autoupdate")
        local dependfile = tmpfile .. ".d"
        local lockfile = io.openlock(tmpfile .. ".lock")
        local kind = localcache.get("vsxmake", "kind")
        local modes = localcache.get("vsxmake", "modes")
        local archs = localcache.get("vsxmake", "archs")
        local outputdir = localcache.get("vsxmake", "outputdir")
        if lockfile:trylock() then
            if os.getenv("XMAKE_IN_VSTUDIO") and not os.getenv("XMAKE_IN_XREPO") then
                local sourcefiles = {}
                for _, target in pairs(project.targets()) do
                    table.join2(sourcefiles, target:sourcefiles(), (target:headerfiles()))
                end
                table.sort(sourcefiles)
                depend.on_changed(function ()
                    -- we use task instead of os.exec("xmake") to avoid the project lock
                    print("update vsxmake project -k %s %s ..", kind or "vsxmake", outputdir or "")
                    task.run("project", {kind = kind or "vsxmake", modes = modes, archs = archs, outputdir = outputdir})
                    print("update vsxmake project ok")
                end, {dependfile = dependfile,
                      files = project.allfiles(),
                      values = sourcefiles})
            end
            lockfile:close()
        end
    end)
