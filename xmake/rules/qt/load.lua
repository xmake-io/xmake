--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- make link for framework
function _link(framework, major)
    if major and framework:startswith("Qt") then
        framework = "Qt" .. major .. framework:sub(3) .. (is_mode("debug") and "d" or "")
    end
    return framework
end

-- the main entry
function main(target, opt)

    -- init options
    opt = opt or {}

    -- get qt sdk
    local qt = target:data("qt")

    -- get major version
    local major = nil
    if qt.sdkver then
        major = qt.sdkver:split('%.')[1]
    end

    -- set kind
    if opt.kind then
        target:set("kind", opt.kind)
    end

    -- add -fPIC
    target:add("cxflags", "-fPIC")
    target:add("mxflags", "-fPIC")
    target:add("asflags", "-fPIC")

    -- need c++11
    target:set("languages", "cxx11")

    -- add defines for the compile mode
    if is_mode("debug") then
        target:add("defines", "QT_QML_DEBUG")
    elseif is_mode("release") then
        target:add("defines", "QT_NO_DEBUG")
    elseif is_mode("profile") then
        target:add("defines", "QT_QML_DEBUG", "QT_NO_DEBUG")
    end

    -- The following define makes your compiler emit warnings if you use
    -- any feature of Qt which as been marked deprecated (the exact warnings
    -- depend on your compiler). Please consult the documentation of the
    -- deprecated API in order to know how to port your code away from it.
    target:add("defines", "QT_DEPRECATED_WARNINGS")

    -- add frameworks
    if opt.frameworks then
        target:add("frameworks", opt.frameworks)
    end

    -- do frameworks for qt
    for _, framework in ipairs(target:get("frameworks")) do

        -- translate qt frameworks
        if framework:startswith("Qt") then

            -- add defines
            target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")
            
            -- add includedirs 
            if is_plat("macosx") then
                target:add("includedirs", path.join(qt.sdkdir, "lib/" .. framework .. ".framework/Headers"))
            else 
                target:add("links", _link(framework, major))
                target:add("includedirs", path.join(qt.sdkdir, "include/" .. framework))
            end
        end
    end

    -- add includedirs, linkdirs 
    if is_plat("macosx") then
        target:add("frameworks", "DiskArbitration", "IOKit")
        target:add("frameworkdirs", qt.linkdirs)
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/macx-clang"))
        target:add("linkdirs", qt.linkdirs)
        target:add("rpathdirs", "@executable_path/Frameworks", qt.linkdirs)
    elseif is_plat("linux") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/linux-g++"))
        target:add("rpathdirs", qt.linkdirs)
        target:add("linkdirs", qt.linkdirs)
    elseif is_plat("windows") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/win32-msvc"))
        target:add("linkdirs", qt.linkdirs)
    elseif is_plat("mingw") then
        target:set("frameworks", nil)
        target:add("includedirs", path.join(qt.sdkdir, "include"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/win32-g++"))
        target:add("linkdirs", qt.linkdirs)
        target:add("links", "mingw32")
    end
end

