
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- includes
includes("qt_add_static_plugins.lua")

-- add target
target("${TARGETNAME}")

    -- add rules
    add_rules("qt.widgetapp_static")

    -- add headerfiles
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h") 

    -- add plugin: QSvgPlugin (optional)
    qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg", "Qt5Svg"}})

${FAQ}
