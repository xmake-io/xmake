add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("foo")
    set_kind("static")
    add_files("src/*.cpp")
    add_files("src/*.mpp")
