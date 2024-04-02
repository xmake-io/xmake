add_rules("mode.debug", "mode.release")

add_requires("lua 5.4", {system = false})

target("foo")
    add_rules("module.shared")
    add_files("src/foo.c")
    add_packages("lua")

