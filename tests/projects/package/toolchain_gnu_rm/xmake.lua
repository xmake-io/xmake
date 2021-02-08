add_rules("mode.debug", "mode.release")
add_requires("gnu-rm")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("@gnu-rm")
