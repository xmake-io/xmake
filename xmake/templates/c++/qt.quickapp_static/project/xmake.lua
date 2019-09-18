
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- includes
includes("qt_add_static_plugins.lua")

-- add target
target("${TARGETNAME}")

    -- add rules
    add_rules("qt.quickapp_static")

    -- add headerfiles
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/qml.qrc")

    -- add plugin: qml.QtQuick
    qt_add_static_plugins("QtQuick2Plugin", {linkdirs = "qml/QtQuick.2", links = "qtquick2plugin"})
    qt_add_static_plugins("QtQuick2WindowPlugin", {linkdirs = "qml/QtQuick/Window.2", links = "windowplugin"})

${FAQ}
