add_rules("mode.debug", "mode.release")

add_requires("lua 5.4")

target("foo")
    add_rules("module.shared")
    add_files("src/foo.cpp")
    add_packages("lua")

