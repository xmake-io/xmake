add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("stl_headerunit")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")

