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
    on_load(function (target)
        target:set("kind", "static")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", "shared")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", "binary")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

    after_install("windows", "install.windows")

-- define rule: qt widgetapp
rule("qt.widgetapp")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app", "qt.qrc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)

        -- get qt sdk version
        local qt = target:data("qt")
        local qt_sdkver = nil
        if qt.sdkver then
            import("core.base.semver")
            qt_sdkver = semver.new(qt.sdkver)
        end

        local frameworks = {"QtGui", "QtWidgets", "QtCore"}
        if qt_sdkver and qt_sdkver:lt("5.0") then
            frameworks = {"QtGui", "QtCore"} -- qt4.x has not QtWidgets, it is in QtGui
        end
        import("load")(target, {gui = true, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")

-- define rule: qt static widgetapp
rule("qt.widgetapp_static")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app", "qt.qrc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)

        -- get qt sdk version
        local qt = target:data("qt")
        local qt_sdkver = nil
        if qt.sdkver then
            import("core.base.semver")
            qt_sdkver = semver.new(qt.sdkver)
        end

        -- @see
        -- https://github.com/xmake-io/xmake/issues/1047
        -- https://github.com/xmake-io/xmake/issues/2791
        local QtPlatformSupport
        if qt_sdkver then
            if qt_sdkver:ge("6.0") then
                QtPlatformSupport = nil
            elseif qt_sdkver:ge("5.9") then
                QtPlatformSupport = "QtPlatformCompositorSupport"
            else
                QtPlatformSupport = "QtPlatformSupport"
            end
        end

        -- load some basic plugins and frameworks
        local plugins = {}
        local frameworks = {"QtGui", "QtWidgets", "QtCore"}
        if qt_sdkver and qt_sdkver:lt("5.0") then
            frameworks = {"QtGui", "QtCore"} -- qt4.x has not QtWidgets, it is in QtGui
        end
        if target:is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "cups"}}
            table.insert(frameworks, "QtWidgets")
            if QtPlatformSupport then
                table.insert(frameworks, QtPlatformSupport)
            end
        elseif target:is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {is_mode("debug") and "qwindowsd" or "qwindows"}}
            table.join2(frameworks, "QtPrintSupport", "QtWidgets")
            if QtPlatformSupport then
                table.insert(frameworks, QtPlatformSupport)
            end
        elseif target:is_plat("wasm") then
            plugins.QWasmIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qwasm"}}
            table.join2(frameworks, "QtEventDispatcherSupport", "QtFontDatabaseSupport", "QtEglSupport")
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")

-- define rule: qt quickapp
rule("qt.quickapp")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore", "QtNetwork"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")

-- define rule: qt static quickapp
rule("qt.quickapp_static")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)

        -- get qt sdk version
        local qt = target:data("qt")
        local qt_sdkver = nil
        if qt.sdkver then
            import("core.base.semver")
            qt_sdkver = semver.new(qt.sdkver)
        end

        -- @see
        -- https://github.com/xmake-io/xmake/issues/1047
        -- https://github.com/xmake-io/xmake/issues/2791
        local QtPlatformSupport
        if qt_sdkver then
            if qt_sdkver:ge("6.0") then
                QtPlatformSupport = nil
            elseif qt_sdkver:ge("5.9") then
                QtPlatformSupport = "QtPlatformCompositorSupport"
            else
                QtPlatformSupport = "QtPlatformSupport"
            end
        end

        -- load some basic plugins and frameworks
        local plugins = {}
        local frameworks = {"QtGui", "QtQuick", "QtQml", "QtQmlModels", "QtCore", "QtNetwork"}
        if target:is_plat("macosx") then
            plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "cups"}}
            table.insert(frameworks, "QtWidgets")
            if QtPlatformSupport then
                table.insert(frameworks, QtPlatformSupport)
            end
        elseif target:is_plat("windows") then
            plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {is_mode("debug") and "qwindowsd" or "qwindows"}}
            table.join2(frameworks, "QtPrintSupport", "QtWidgets")
            if QtPlatformSupport then
                table.insert(frameworks, QtPlatformSupport)
            end
        elseif target:is_plat("wasm") then
            plugins.QWasmIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qwasm"}}
            table.join2(frameworks, "QtEventDispatcherSupport", "QtFontDatabaseSupport", "QtEglSupport")
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")

-- define rule: qt qmlplugin
rule("qt.qmlplugin")
    add_deps("qt.shared", "qt.qmltyperegistrar")
    on_load(function(target)
        import("load")(target, {frameworks = { "QtCore", "QtGui", "QtQuick", "QtQml", "QtNetwork" }})
    end)

-- define rule: qt application (deprecated)
rule("qt.application")
    add_deps("qt.quickapp", "qt.ui")
