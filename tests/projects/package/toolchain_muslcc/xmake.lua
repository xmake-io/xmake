add_rules("mode.debug", "mode.release")
add_requires("muslcc")
add_requires("zlib")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")
    set_toolchains("muslcc", {packages = "muslcc"})
