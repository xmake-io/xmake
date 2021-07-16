add_requireconfs("*", {system = false, configs = {debug = false}})
add_requires("zlib", {system = false, debug = true})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")
