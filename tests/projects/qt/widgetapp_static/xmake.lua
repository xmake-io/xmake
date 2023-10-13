add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

target("demo")
    add_rules("qt.widgetapp_static")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")
    add_files("src/mainwindow.h")
    add_frameworks("QtSvg")
    qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg"}})
