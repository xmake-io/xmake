add_rules("mode.debug", "mode.release")

includes("@builtin/qt")

-- use the qt.qml rule directly instead of qt_add_qml_module(), the qml file
-- extensions are dispatched by the rule, the module settings are set by add_values()
target("qml_module_rule")
    add_rules("qt.quickapp", "qt.qml")
    add_files("main.cpp", "*.qml", "*.js", "src/*.mjs")
    add_files("qmldir")
    add_files("assets/*.svg", {rules = "qt.qml.resource"})
    add_values("qt.qml.uri", "MyApp")
    set_runenv("QT_QPA_PLATFORM", "offscreen")
