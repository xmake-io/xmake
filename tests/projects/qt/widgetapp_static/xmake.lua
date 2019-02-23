
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("qt_demo")

    -- add rules
    add_rules("qt.application")

    -- add headers
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h") 

    -- add frameworks
    add_frameworks("QtWidgets")

    -- add plugin: platforms
    add_values("qt.linkdirs", "plugins/platforms")
    if is_plat("macosx") then
        add_values("qt.links", "qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "cups")
        add_values("qt.plugins", "QCocoaIntegrationPlugin")
    elseif is_plat("windows") then
        add_values("qt.links", "Qt5PrintSupport", "Qt5PlatformSupport", "cups")
        add_values("qt.plugins", "QWindowsIntegrationPlugin")
    end

    -- add plugin: imageformats.QSvgPlugin (optional)
    --[[
    add_values("qt.linkdirs", "plugins/imageformats")
    add_values("qt.links", "qsvg", "Qt5Svg")
    add_values("qt.plugins", "QSvgPlugin")
    ]]
