add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

target("qml_module_only_bytecode")
    add_rules("qt.quickapp")
    add_files("main.cpp")
    qt_add_qml_module("*.qml", "*.js", "assets/*.svg", {uri = "MyApp", only_bytecode = true})
    set_runenv("QT_QPA_PLATFORM", "offscreen")
