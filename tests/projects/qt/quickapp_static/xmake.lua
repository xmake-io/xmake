
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
    add_files("src/qml.qrc")

    -- add frameworks
    add_frameworks("QtQuick")

    -- add plugin: platforms
    add_values("qt.linkdirs", "plugins/platforms")
    if is_plat("macosx") then
        add_values("qt.links", "qcocoa", "Qt5PrintSupport", "Qt5PlatformSupport", "Qt5Widgets", "cups")
        add_values("qt.plugins", "QCocoaIntegrationPlugin")
    elseif is_plat("windows") then
        add_values("qt.links", "Qt5PrintSupport", "Qt5PlatformSupport", "cups")
        add_values("qt.plugins", "QWindowsIntegrationPlugin")
    end

    -- add plugin: qml.QtQuick
    add_values("qt.linkdirs", "qml/QtQuick.2")
    add_values("qt.links", "qtquick2plugin")

