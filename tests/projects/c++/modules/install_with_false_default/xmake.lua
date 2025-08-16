add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("module_test")
    set_kind("moduleonly")
    add_files("src/*.mpp")

target("module_test1")
    set_kind("binary")
    set_default(false)
    add_deps("module_test")
    add_files("src/*.cpp")
