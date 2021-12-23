add_rules("mode.release", "mode.debug")
add_requires("python 3.x")

target("example")
    add_rules("swig.c", {moduletype = "python", soabi = true})
    add_files("src/example.i", {scriptdir = "share"})
    add_files("src/example.c")
    add_packages("python")
