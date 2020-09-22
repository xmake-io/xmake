add_rules("mode.debug", "mode.release")

includes("qt_add_static_plugins.lua")

target("demo")
    add_rules("qt.widgetapp_static")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")
    add_files("src/mainwindow.h")
    qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg", "Qt5Svg"}})
