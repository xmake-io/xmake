add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("test-phony")
    set_kind("phony")
    add_files("src/*.mpp", {public = true})

target("class")
    set_kind("binary")
    add_files("src/*.cpp")
    add_deps("test-phony")

