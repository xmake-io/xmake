add_rules("mode.debug", "mode.release")

target("foo")
    add_rules("module.shared")
    add_files("src/*.cpp")
    set_languages("c++11")
