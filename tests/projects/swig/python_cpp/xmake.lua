add_rules("mode.release", "mode.debug")
add_requires("python 3.x")

target("example")
    add_rules("swig.cpp")
    add_files("src/example.i", {moduletype = "python", scriptdir = "share"})
    add_files("src/example.cpp")
    add_packages("python")
