add_rules("mode.debug", "mode.release")

add_requires("foo")
add_repositories("myrepo ./repo")

target("console")
    set_kind("binary")
    add_files("src/main.cpp", "src/*.md")
    add_packages("foo")
    add_rules("@foo/markdown")

