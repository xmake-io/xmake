add_rules("mode.release", "mode.debug")
set_languages("c++23")

target("hello")
    set_kind("binary")
    add_files("src/*.mpp")
