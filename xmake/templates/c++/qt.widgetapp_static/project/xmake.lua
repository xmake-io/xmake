add_rules("mode.debug", "mode.release")

includes("qt_add_static_plugins.lua")

target("${TARGETNAME}")
    add_rules("qt.widgetapp_static")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h")

    -- add plugin: QSvgPlugin (optional)
    add_frameworks("QtSvg")
    qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg"}})

${FAQ}
