
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- includes
includes("qt_add_static_plugins.lua")

-- add target
target("[targetname]")

    -- add rules
    add_rules("qt.quickapp")

    -- add headers
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/qml.qrc")

    -- add plugin: QXXXIntegrationPlugin
    if is_plat("macosx") then
        qt_add_static_plugins("QCocoaIntegrationPlugin", {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "cups"}})
    elseif is_plat("windows") then
        qt_add_static_plugins("QWindowsIntegrationPlugin", {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "qwindows"}})
    end

    -- add plugin: qml.QtQuick
    qt_add_static_plugins("QtQuick2Plugin", {linkdirs = "qml/QtQuick.2", links = "qtquick2plugin"})
    qt_add_static_plugins("QtQuick2WindowPlugin", {linkdirs = "qml/QtQuick/Window.2", links = "windowplugin"})

