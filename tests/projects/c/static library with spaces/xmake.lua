add_rules("mode.release", "mode.debug")

target("test")
    set_kind("static")
    add_files("s r c/interface.c")
    add_includedirs("$(projectdir)/s r c", {public = true})

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("s r c/test.c")


