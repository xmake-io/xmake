add_rules("mode.debug", "mode.release")
set_languages("c++latest")

target("foo")
    set_kind("static")
    add_files("src/foo.cpp")
    add_files("src/foo.mpp", {public = true})

target("bar")
    set_kind("moduleonly")
    add_files("src/bar.mpp")

target("main")
    set_kind("binary")
    add_deps("foo", "bar")
    add_files("src/main.cpp")
