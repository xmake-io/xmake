add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("bar")
    set_kind("headeonly")
    add_rules("moduleonly")
    add_files("*.mpp")
