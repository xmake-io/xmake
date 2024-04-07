add_rules("mode.debug", "mode.release")

add_requires("cppfront")

target("test")
    add_rules("cppfront")
    set_kind("binary")
    add_files("src/*.cpp2")
    add_packages("cppfront")

