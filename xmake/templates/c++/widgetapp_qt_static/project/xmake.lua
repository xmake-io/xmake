
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- includes
includes("qt_add_static_plugins.lua")

-- add target
target("[targetname]")

    -- add rules
    add_rules("qt.widgetapp")

    -- add headers
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h") 

    -- add plugin: QXXXIntegrationPlugin
    if is_plat("macosx") then
        qt_add_static_plugins("QCocoaIntegrationPlugin", {linkdirs = "plugins/platforms", links = {"qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "cups"}})
    elseif is_plat("windows") then
        qt_add_static_plugins("QWindowsIntegrationPlugin", {linkdirs = "plugins/platforms", links = {"Qt5PrintSupport", "Qt5PlatformSupport", "qwindows"}})
    end

    -- add plugin: QSvgPlugin (optional)
    qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg", "Qt5Svg"}})
