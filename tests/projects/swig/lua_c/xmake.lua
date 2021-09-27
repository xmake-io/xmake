add_rules("mode.release", "mode.debug")
add_requires("lua")

target("example")
    add_rules("swig.c")
    add_files("src/example.i", {moduletype = "lua", scriptdir = "share"})
    add_files("src/example.c")
    add_packages("lua")
