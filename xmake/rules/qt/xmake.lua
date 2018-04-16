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
-- @file        xmake.lua
--

-- define rule: base
rule("qt:base")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")
        import("detect.sdks.find_qt")

        -- check qt sdk
        local qt = assert(find_qt(nil, {verbose = true}), "Qt SDK not found!")

        -- set kind: binary
        target:set("kind", "binary")

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

        -- add frameworks: QtCore
        target:add("frameworks", "QtCore")

        -- do frameworks for qt
        for _, framework in ipairs(target:get("frameworks")) do

            -- translate qt frameworks
            if framework:startswith("Qt") then

                -- add defines
                target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")
                
                -- add includedirs for macosx
                if is_plat("macosx") then
                    target:add("includedirs", path.join(qt.sdkdir, "lib/" .. framework .. ".framework/Headers"))
                end
            end
        end

        -- add includedirs, linkdirs for macosx
        if is_plat("macosx") then
            target:add("frameworkdirs", qt.linkdirs)
            target:add("frameworks", "DiskArbitration", "IOKit")
            target:add("includedirs", path.join(qt.sdkdir, "mkspecs/macx-clang"))
            target:add("rpathdirs", "@executable_path/Frameworks", qt.linkdirs)
        end
    end)

-- define rule: *.qrc
rule("qt:qrc")
    set_extensions(".qrc")
    on_build_file(function (target, sourcefile)
        print(sourcefile)
    end)

-- define rule: qt static library
rule("qt:static")

    -- add base rule
    add_deps("qt:base")

    -- on load
    on_load(function (target)
        target:set("kind", "static")
    end)

-- define rule: qt shared library
rule("qt:shared")

    -- add base rule
    add_deps("qt:base")

    -- on load
    on_load(function (target)
        target:set("kind", "shared")
    end)

-- define rule: qt console
rule("qt:console")

    -- add base rule
    add_deps("qt:base")

    -- on load
    on_load(function (target)
        target:set("kind", "binary")
    end)

-- define rule: qt widget application
rule("qt:widgetapp")

    -- add base rule
    add_deps("qt:base")

    -- on load
    on_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")
    end)

-- define rule: qt quick application
rule("qt:quickapp")

    -- add rules
    add_deps("qt:qrc", "qt:base")

    -- on load
    on_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- add frameworks
        target:add("frameworks", "QtQuick", "QtGui")

        -- TODO
        -- import("load")(target, {kind = "binary", frameworks = {"QtQuick", "QtGui", "QtCore"}})
    end)
