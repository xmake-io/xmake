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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: qt/wasm application
rule("qt._wasm_app")
    add_deps("qt.env")
    after_build(function (target)
        local qt = target:data("qt")
        local pluginsdir = qt and qt.pluginsdir
        if pluginsdir then
            local targetdir = target:targetdir()
            local htmlfile = path.join(targetdir, target:basename() .. ".html")
            if os.isfile(path.join(pluginsdir, "platforms/wasm_shell.html")) then
                os.vcp(path.join(pluginsdir, "platforms/wasm_shell.html"), htmlfile)
                io.gsub(htmlfile, "@APPNAME@", target:name())
                os.vcp(path.join(pluginsdir, "platforms/qtloader.js"), targetdir)
                os.vcp(path.join(pluginsdir, "platforms/qtlogo.svg"), targetdir)
            end
        end
    end)

-- define rule: qt static library
rule("qt.static")
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "static")
    end)

    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "shared")
    end)

    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "binary")
    end)

    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt widgetapp
rule("qt.widgetapp")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    after_load(function (target)
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtWidgets", "QtCore"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt static widgetapp
rule("qt.widgetapp_static")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    after_load(function (target)
        local plugins = {}
        if is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "cups"}}
        elseif is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "qwindows"}}
        elseif is_plat("wasm") then
            plugins.QWasmIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5EventDispatcherSupport", "Qt5FontDatabaseSupport", "Qt5EglSupport", "qwasm"}}
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = {"QtGui", "QtWidgets", "QtCore"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt quickapp
rule("qt.quickapp")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    after_load(function (target)
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore", "QtNetwork"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt static quickapp
rule("qt.quickapp_static")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    after_load(function (target)
        local plugins = {}
        if is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "cups"}}
        elseif is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "qwindows"}}
        elseif is_plat("wasm") then
            plugins.QWasmIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"Qt5EventDispatcherSupport", "Qt5FontDatabaseSupport", "Qt5EglSupport", "qwasm"}}
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = {"QtGui", "QtQuick", "QtQml", "QtQmlModels", "QtCore", "QtNetwork"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")

-- define rule: qt application (deprecated)
rule("qt.application")
    add_deps("qt.quickapp", "qt.ui")
