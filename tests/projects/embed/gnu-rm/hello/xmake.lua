add_rules("mode.debug", "mode.release")

add_requires("gnu-rm")
set_toolchains("@gnu-rm")

target("foo")
    add_rules("gnu-rm.static")
    add_files("src/foo/*.c")

target("hello")
    add_deps("foo")
    add_rules("gnu-rm.binary")
    add_files("src/*.c", "src/*.s")
    add_files("src/*.ld")
    add_includedirs("src/lib/cmsis")
