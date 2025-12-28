add_rules("mode.debug", "mode.release")
set_languages("c++23")

target("module_dep")
    set_kind("moduleonly")
    add_files("src/*.cppm")

target("module_target1")
    set_kind("moduleonly")
    add_files("src/*.cppm")
    add_deps("module_dep")
    add_tests("tests", {kind = "binary", files = "src/main.cpp", build_should_pass = true, run_should_pass = true})
