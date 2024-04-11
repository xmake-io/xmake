add_rules("mode.debug", "mode.release")

target("generate")
    add_rules("module.binary")
    add_files("src/*.cpp")
    set_languages("c++11")
