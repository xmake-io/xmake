add_rules("mode.debug", "mode.release")

target("demo")
    add_rules("qt.qmlplugin")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")

    if is_plat("windows") then
        add_cxxflags("/permissive-")
    end

    set_values("qml.plugin.importname", "My.Plugin")