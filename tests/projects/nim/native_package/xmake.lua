add_rules("mode.debug", "mode.release")

add_requires("zlib")

target("test")
    set_kind("binary")
    add_files("src/main.nim")
    add_packages("zlib")
