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

rule("luarocks.module")
    on_load(function (target)

        -- imports
        import("core.cache.detectcache")
        import("core.project.target", {alias = "project_target"})

        -- set kind
        if target:is_plat("macosx") then
            target:set("kind", "binary")
            target:add("ldflags", "-bundle", "-undefined dynamic_lookup", {force = true})
        else
            target:set("kind", "shared")
        end

        -- set library name
        local modulename = target:name():split('.', {plain = true})
        modulename = modulename[#modulename]
        if target:is_plat("windows", "mingw") then
            target:set("basename", modulename)
        else
            target:set("filename", modulename .. ".so")
        end

        -- export symbols
        if target:is_plat("windows") then
            local exported_name = target:name():gsub("%.", "_")
            exported_name = exported_name:match('^[^%-]+%-(.+)$') or exported_name
            target:add("shflags", "/export:luaopen_" .. exported_name, {force = true})
        else
            target:set("symbols", "none")
        end

        -- add lua library
        local has_lua = false
        local includedirs = get_config("includedirs") -- pass lua library from luarocks-build-xmake/xmake.lua
        if includedirs and includedirs:find("lua", 1, true) then
            has_lua = true
        end
        if not has_lua then
            -- user use `add_requires/add_packages` to add lua/luajit package
            for _, pkg in ipairs(target:get("packages")) do
                if pkg == "lua" or pkg == "luajit" then
                    has_lua = true
                    break
                end
            end
        end
        if not has_lua then
            target:add(find_package("lua"))
        end
    end)
    on_install(function (target)
        local moduledir = path.directory((target:name():gsub('%.', '/')))
        import('target.action.install')(target, {libdir = path.join('lib', moduledir), bindir = path.join('lib', moduledir)})
    end)
