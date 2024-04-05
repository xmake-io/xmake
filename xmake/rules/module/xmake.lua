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

rule("module.binary")
    on_load(function (target)
        import("core.project.config")
        target:set("kind", "binary")
        target:set("basename", "module_" .. target:name())
        target:set("targetdir", config.buildir())
    end)

rule("module.shared")
    add_deps("utils.symbols.export_all")
    on_load(function (target)
        import("core.project.config")
        target:set("kind", "shared")
        target:set("basename", "module_" .. target:name())
        target:set("targetdir", config.buildir())
        target:set("strip", "none")
        target:add("includedirs", path.join(os.programdir(), "scripts", "module"))
        target:add("includedirs", path.join(os.programdir(), "scripts", "module", "luawrap"))
        if xmake.luajit() then
            target:add("defines", "XMI_USE_LUAJIT")
        end
    end)

