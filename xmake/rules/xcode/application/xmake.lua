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

-- define rule: xcode application
rule("xcode.application")

    -- support add_files("Info.plist", "*.storyboard", "*.xcassets", "*.metal")
    add_deps("xcode.info_plist", "xcode.storyboard", "xcode.xcassets", "xcode.metal")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load("load")

    -- depend xcode.framework? we need disable `build.across_targets_in_parallel` policy
    after_load(function (target)
        local across_targets_in_parallel
        for _, dep in ipairs(target:orderdeps()) do
            if dep:rule("xcode.framework") then
                across_targets_in_parallel = false
            end
        end
        if across_targets_in_parallel ~= nil then
            target:set("policy", "build.across_targets_in_parallel", across_targets_in_parallel)
        end
    end)

    -- build *.app
    after_build("build")

    -- package *.app to *.ipa (iphoneos) or *.dmg (macosx)
    on_package("package")

    -- install application
    on_install("install")

    -- uninstall application
    on_uninstall("uninstall")

    -- run application
    on_run("run")
