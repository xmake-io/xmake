add_requires("zlib", {system = false})
add_requires("zlib", {system = false}) -- test repeat requires
add_requires("zlib~debug", {system = false, debug = true})
add_requires("zlib~shared", {system = false, configs = {shared = true}, alias = "zlib_shared"})

target("test1")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")

target("test2")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib#debug")

target("test3")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib_shared")
