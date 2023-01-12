add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("stl_headerunit_cpp_only")
    set_kind("binary")
    add_files("src/*.cpp")
    set_policy("build.c++.modules", true)

