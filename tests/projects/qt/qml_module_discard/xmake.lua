add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

target("qml_module_discard")
    add_rules("qt.quickapp")
    add_files("main.cpp")
    qt_add_qml_module("*.qml", "*.js", "assets/*.svg", {uri = "MyApp", discard = true})
    set_runenv("QT_QPA_PLATFORM", "offscreen")
