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
-- @file        load.lua
--

-- main entry
function main (target)

    -- get bundle directory
    local targetdir = target:targetdir()
    local bundledir = path.join(targetdir, target:basename() .. ".app")
    target:data_set("xcode.bundle.rootdir", bundledir)

    -- get contents and resources directory
    local contentsdir = bundledir
    local resourcesdir = bundledir
    if target:is_plat("macosx") then
        contentsdir = path.join(bundledir, "Contents")
        resourcesdir = path.join(bundledir, "Contents", "Resources")
    end
    target:data_set("xcode.bundle.contentsdir", contentsdir)
    target:data_set("xcode.bundle.resourcesdir", resourcesdir)

    -- set target directory for app
    target:set("kind", "binary")
    target:set("filename", target:basename())

    -- set install directory
    if target:is_plat("macosx") and not target:get("installdir") then
        target:set("installdir", "/Applications")
    end

    -- add frameworks
    if target:is_plat("macosx") then
        local xcode = target:toolchain("xcode")
        if xcode and xcode:config("appledev") == "catalyst" then
            target:add("frameworks", "UIKit")
        else
            target:add("frameworks", "AppKit")
        end
    else
        target:add("frameworks", "UIKit")
    end

    -- register clean files for `xmake clean`
    target:add("cleanfiles", bundledir)
end
