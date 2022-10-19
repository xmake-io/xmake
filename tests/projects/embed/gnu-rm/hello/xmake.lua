set_toolchains("gnu-rm")

add_rules("mode.debug", "mode.release")

target("foo")
    add_rules("gnu-rm.static")
    add_files("src/foo/*.c")

target("hello")
    add_deps("foo")
    add_rules("gnu-rm.binary")
    set_kind("binary")
    add_files("src/*.c", "src/*.s")
    add_files("src/*.ld")
    add_includedirs("src/lib/cmsis")
