add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

target("qml_module")
    add_rules("qt.quickapp")
    add_files("main.cpp")
    qt_add_qml_module("*.qml", "*.js", "src/*.mjs", "assets/*.svg", {uri = "MyApp"})
    set_runenv("QT_QPA_PLATFORM", "offscreen")
