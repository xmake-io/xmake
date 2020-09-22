add_rules("mode.debug", "mode.release")

includes("qt_add_static_plugins.lua")

target("demo")
    add_rules("qt.quickapp_static")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/qml.qrc")
    add_frameworks("QtQuickControls2", "QtQuickTemplates2")
    qt_add_static_plugins("QtQuick2Plugin", {linkdirs = "qml/QtQuick.2", links = "qtquick2plugin"})
    qt_add_static_plugins("QtQuick2WindowPlugin", {linkdirs = "qml/QtQuick/Window.2", links = "windowplugin"})
    qt_add_static_plugins("QtQuickControls2Plugin", {linkdirs = "qml/QtQuick/Controls.2", links = "qtquickcontrols2plugin"})
    qt_add_static_plugins("QtQuickTemplates2Plugin", {linkdirs = "qml/QtQuick/Templates.2", links = "qtquicktemplates2plugin"})

