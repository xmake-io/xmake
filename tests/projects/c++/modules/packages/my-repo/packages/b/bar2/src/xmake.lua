add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("bar2")
    set_kind("headeronly")
    add_rules("c++.moduleonly")
    add_files("*.mpp")
