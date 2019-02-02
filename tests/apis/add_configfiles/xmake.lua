
target("test")
    set_kind("binary")
    add_files("*.c")

    set_configdir("$(buildir)/config")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config.h.in", {hello = "xmake", prefixdir = "header"})
    add_configfiles("*.man", {copyonly = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config/header")


target("test2")
    set_kind("binary")
    add_files("*.c")

    set_configdir("$(buildir)/config2")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config.h.in", {hello = "xmake", prefixdir = "header"})
    add_configfiles("*.man", {copyonly = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config2/header")
