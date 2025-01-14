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
-- @author      Wu, Zhenyu
-- @file        xmake.lua
--

-- usage:
--
-- add_requires("node-addon-api")
--
-- target("foo")
-- do
--     set_languages("cxx17")
--     add_rules("nodejs.module")
--     add_packages("node-addon-api")
--     add_files("*.cc")
-- end
rule("nodejs.module")
    on_config(function(target)
        -- imports
        import("core.cache.detectcache")
        import("core.project.target", { alias = "project_target" })

        -- set kind
        if target:is_plat("macosx") then
            target:set("kind", "binary")
            target:add("ldflags", "-bundle", "-undefined dynamic_lookup", { force = true })
        else
            target:set("kind", "shared")
        end

        -- export symbols
        if target:is_plat("windows") then
            target:add("shflags", "/export:napi_register_module_v1", "/export:node_api_module_get_api_version_v1",
                { force = true })
        else
            target:set("symbols", "none")
        end

        -- https://github.com/nodejs/node-addon-api/issues/1021
        if target:is_plat("mingw") then
            target:add("packages", "node-api-stub")
            target:add("deps", target:pkg("node-api-stub"))
        end

        -- set library name
        local modulename = target:name():split('.', { plain = true })
        modulename = modulename[#modulename]
        target:set("filename", modulename .. ".node")
    end)

    on_install(function(target)
        if target:is_plat("macosx") then
            target:set("kind", "shared")
        end
        local moduledir = path.directory((target:name():gsub('%.', '/')))
        local mode = get_config("mode")
        local installdir = path.join("build", mode:sub(1, 1):upper() .. mode:sub(2))
        import("target.action.install")(target, {
            installdir = installdir,
            libdir = moduledir,
            bindir = moduledir,
            includedir = path.join("include", moduledir)
        })
    end)
