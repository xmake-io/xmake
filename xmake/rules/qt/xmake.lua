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

-- define rule: qt static library
rule("qt.static")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- after load
    after_load(function (target)
        import("load")(target, {kind = "static", frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- after load
    after_load(function (target)
        import("load")(target, {kind = "shared", frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- after load
    after_load(function (target)
        import("load")(target, {kind = "binary", frameworks = {"QtCore"}})
    end)

-- define rule: qt application
rule("qt.application")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- after load
    after_load(function (target)

        -- load common flags to target
        import("load")(target, {kind = "binary", frameworks = {"QtGui", "QtQml", "QtNetwork", "QtCore"}})

        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("ldflags", "-Wl,-subsystem:windows", {force = true})
        end
    end)

