add_rules("mode.release", "mode.debug")
set_languages("c++2b")

add_repositories("my-repo my-repo")
add_requires("foo", "bar", "bar2")

target("dep")
    set_kind("static")
    add_packages("foo", "bar")
    add_files("src/*.mpp", {public = true})

target("packages")
    set_kind("binary")
    add_files("src/*.cpp")
    add_deps("dep")
    add_packages("foo", "bar", "bar2")
    set_policy("build.c++.modules", true)
