add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("dependence2")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
    set_policy("build.c++.modules.hide_dependencies", true)
