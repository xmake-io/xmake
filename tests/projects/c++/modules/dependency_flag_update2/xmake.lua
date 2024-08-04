add_rules("mode.release", "mode.debug")
set_languages("c++20")

option("foo")
    set_default("true")
    add_defines("FOO")

target("dependency_flag_update3")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
    add_options("foo")

