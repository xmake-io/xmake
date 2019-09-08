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
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtWidgets", "QtCore"}})
    end)

    -- deploy application for android after build
    after_build("android", "deploy.android")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt static widgetapp
rule("qt.widgetapp_static")

    -- add rules
    add_deps("qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    -- after load
    after_load(function (target)
        local plugins = {}
        if is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "cups"}}
        elseif is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "qwindows"}}
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = {"QtGui", "QtWidgets", "QtCore"}})
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
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore"}})
    end)

    -- deploy application for android after build
    after_build("android", "deploy.android")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt static quickapp
rule("qt.quickapp_static")

    -- add rules
    add_deps("qt.qrc", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    -- after load
    after_load(function (target)
        local plugins = {}
        if is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "cups"}}
        elseif is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "qwindows"}}
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore"}})
    end)

    -- deploy application for android after build
    after_build("android", "deploy.android")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt application
rule("qt.application")
    add_deps("qt.quickapp")
