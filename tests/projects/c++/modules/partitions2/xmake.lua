add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("partition2")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
