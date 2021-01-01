add_requires("zlib", {system = false})
add_requires("zlib", {system = false}) -- test repeat requires
add_requires("zlib", {system = false, debug = true, alias = "zlib_debug"})
add_requires("zlib", {system = false, configs = {shared = true}, alias = "zlib_shared"})

target("test1")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")

target("test2")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib_debug")

target("test3")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib_shared")
