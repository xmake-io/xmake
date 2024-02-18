add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("mod")
    set_kind("moduleonly")
    add_files("src/mod.mpp")
