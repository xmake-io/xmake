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
-- @file        xmake.lua
--

rule("csharp.build")
    set_sourcekinds("cs")
    on_load(function (target)
        import("modules.csharp_common", {rootdir = os.scriptdir(), alias = "csharp_common"})

        -- set target extension and prefix
        if target:is_shared() then
            if not target:get("extension") then
                target:set("extension", ".dll")
            end
            if target:get("prefixname") == nil then
                target:set("prefixname", "")
            end
        end

        -- find or generate .csproj file
        local csprojfile = csharp_common.find_or_generate_csproj(target, {skip_deps = true})
        if csprojfile then
            target:data_set("csharp.csproj", csprojfile)
            if not target:get("filename") and not target:get("basename") then
                target:set("basename", path.basename(csprojfile))
            end
        end
    end)
    on_build("build.target")

rule("csharp")
    add_deps("csharp.build")
    add_deps("utils.inherit.links")
