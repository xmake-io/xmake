add_rules("mode.debug", "mode.release")

set_languages("c++latest")

target("stdmodules_cpp_only")
    set_kind("binary")
    add_files("src/*.cpp")
    set_policy("build.c++.modules", true)

