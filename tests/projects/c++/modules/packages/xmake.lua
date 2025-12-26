add_rules("mode.release", "mode.debug")
set_languages("c++20")

add_repositories("my-repo my-repo")
add_requires("foo", "bar", "bar2")

target("packages")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("foo", "bar", "bar2")
    set_policy("build.c++.modules", true)
