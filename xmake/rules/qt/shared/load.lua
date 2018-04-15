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

-- imports
import("core.project.config")
import("detect.sdks.find_qt")

-- the main entry
function main(target)

    -- check qt sdk
    local qt = assert(find_qt(nil, {verbose = true}), "Qt SDK not found!")

    -- set kind: shared
    target:set("kind", "shared")

    -- add defines for using gui and core libs
    target:add("defines", "QT_GUI_LIB", "QT_CORE_LIB")

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

    -- add includedirs and linkdirs for macosx
    if is_plat("macosx") then
        target:add("frameworkdirs", qt.linkdirs)
        target:add("frameworks", "QtCore", "DiskArbitration", "IOKit")
        target:add("includedirs", path.join(qt.sdkdir, "lib/QtCore.framework/Headers"))
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/macx-clang"))
        target:add("rpathdirs", "@executable_path/Frameworks", qt.linkdirs)
    end
end
