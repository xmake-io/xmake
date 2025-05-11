add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("test")
    set_kind("static")
    add_includedirs("include")
    add_files("src/*.mpp", {public = true})

target("test-phony")
    set_kind("phony")
    add_deps("test")

target("class")
    set_kind("binary")
    add_files("src/*.cpp")
    add_deps("test-phony")

