add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("culling")
    set_kind("static")
    add_files("src/*.mpp")
    set_policy("build.c++.modules.culling", false)
