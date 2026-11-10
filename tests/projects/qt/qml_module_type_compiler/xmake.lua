add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

target("qml_module_type_compiler")
    add_rules("qt.quickapp")
    add_files("main.cpp")
    -- the qmldir type entries use major.minor (2.3), e.g. 2.3.4 -> 2.3
    qt_add_qml_module("*.qml", "*.js", "assets/*.svg", {uri = "MyApp", version = "2.3.4", type_compiler = true, namespace = "MyAppNs"})
    set_runenv("QT_QPA_PLATFORM", "offscreen")
