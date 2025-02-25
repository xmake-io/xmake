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

rule("kotlin-native.build")
    set_sourcekinds("kc")
    on_load(function (target)
        target:add("kcflags", "-opt-in=kotlinx.cinterop.ExperimentalForeignApi", {force = true})
        if target:is_static() then
            target:add("arflags", {"-produce", "static"}, {force = true})
            target:add("includedirs", target:targetdir(), {interface = true})
            target:add("kcflags", "-opt-in=kotlin.experimental.ExperimentalNativeApi", {force = true})
            if target:is_plat("macosx") then
                target:add("frameworks", "Foundation", "CoreFoundation", {interface = true})
            elseif target:is_plat("mingw") then
                target:add("syslinks", "pthread", {interface = true})
            end
        elseif target:is_shared() then
            target:add("shflags", {"-produce", "dynamic"}, {force = true})
            target:add("kcflags", "-opt-in=kotlin.experimental.ExperimentalNativeApi", {force = true})
            target:add("includedirs", target:targetdir(), {interface = true})
        end
        target:set("policy", "build.fence", true)
    end)
    on_build("build.target")

rule("kotlin-native")
    add_deps("kotlin-native.build")
    add_deps("utils.inherit.links")
