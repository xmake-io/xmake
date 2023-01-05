add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("bar")
    set_kind("static")
    add_files("*.cpp", "*.mpp")
