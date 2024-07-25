add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("bar")
    set_kind("static")
    add_files("src/bar.mpp", {public = true})
    add_files("src/bar.cpp")

target("foo")
    set_kind("static")
    add_deps("bar")
    add_files("src/foo.mpp", {public = true})
    add_files("src/foo.cpp")

target("hello")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")
