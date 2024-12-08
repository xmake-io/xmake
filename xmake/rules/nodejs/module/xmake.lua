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

rule("nodejs.module")
    on_load(function(target)
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
        if is_plat("mingw") then
            import("core.project.config")
            local outputdir = path.join(target:autogendir(), "/node-api-stub")
            if not os.isdir(outputdir) then
                import("devel.git")
                git.clone("https://github.com/napi-bindings/node-api-stub", { depth = 1, outputdir = outputdir })
            end
            target:add("files", path.join(outputdir, "node_api.c"))
        end

        -- set library name
        local modulename = target:name():split('.', { plain = true })
        modulename = modulename[#modulename]
        target:set("filename", modulename .. ".node")

        -- add node library
        local has_node = false
        local includedirs = get_config("includedirs") -- pass node library from nodejs/xmake.lua
        if includedirs and includedirs:find("node-api-headers", 1, true) then
            has_node = true
        end
        if not has_node then
            -- user use `add_requires/add_packages` to add node package
            for _, pkg in ipairs(target:get("packages")) do
                if pkg == "node-api-headers" then
                    has_node = true
                    break
                end
            end
        end
        if not has_node then
            target:add(find_package("node-api-headers"))
        end
    end)
    on_install(function(target)
        if target:is_plat("macosx") then
            target:set("kind", "shared")
        end
        local moduledir = path.directory((target:name():gsub('%.', '/')))
        local installdir = path.join("build", get_config("mode"))
        import("target.action.install")(target, {
            installdir = installdir,
            libdir = moduledir,
            bindir = moduledir,
            includedir = path.join("include", moduledir)
        })
    end)
