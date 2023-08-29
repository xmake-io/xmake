add_rules("mode.debug", "mode.release")

target("test")
    add_rules("cppfront")
    set_kind("binary")
    add_files("src/*.cpp2")

