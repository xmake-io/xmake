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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: qt static library
rule("qt.static")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "static")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "shared")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "binary")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt widgetapp
rule("qt.widgetapp")

    -- add rules
    add_deps("qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    -- after load
    after_load(function (target)

        -- load common flags to target
        import("load")(target, {frameworks = {"QtGui", "QtWidgets", "QtCore"}})

        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("ldflags", "-Wl,-subsystem:windows", {force = true})
        end
    end)

    -- deploy application for android after build
    after_build("android", "deploy.android")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt quickapp
rule("qt.quickapp")

    -- add rules
    add_deps("qt.qrc", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    -- after load
    after_load(function (target)

        -- load common flags to target
        import("load")(target, {frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore"}})

        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("ldflags", "-Wl,-subsystem:windows", {force = true})
        end
    end)

    -- deploy application for android after build
    after_build("android", "deploy.android")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt application
rule("qt.application")
    add_deps("qt.quickapp")
