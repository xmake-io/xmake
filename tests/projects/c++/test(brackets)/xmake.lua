add_rules("mode.debug", "mode.release")

target("demo")
    set_kind("binary")
    add_files("src/*.cpp")
    add_includedirs("inc(brackets)")
    add_defines("WORD=\"(world)\"")

