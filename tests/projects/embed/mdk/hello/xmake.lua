add_rules("mode.debug", "mode.release")

set_runtimes("microlib")

target("foo")
    add_rules("mdk.static")
    add_files("src/foo/*.c")

target("hello")
    add_deps("foo")
    add_rules("mdk.binary")
    add_files("src/*.c", "src/*.s")
    add_includedirs("src/lib/cmsis")
