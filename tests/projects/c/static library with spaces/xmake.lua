add_rules("mode.release", "mode.debug")

target("test")
    set_kind("static")
    add_files("s r c/interface.c")
    add_sysincludedirs("$(projectdir)/i n c", {public = true})

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("s r c/test.c")
    set_pcheader("$(projectdir)/i n c/stdafx.h")


