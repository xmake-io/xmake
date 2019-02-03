
target("test")
    set_kind("binary")
    add_files("main.c")

    set_configdir("$(buildir)/config")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config.h.in", {variables = {hello = "xmake", module = "test"}, prefixdir = "header"})
    add_configfiles("*.man", {copyonly = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config/header")


target("test2")
    set_kind("binary")
    add_files("main2.c")

    set_configdir("$(buildir)/config2")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config2.h.in", {variables = {hello = "xmake2", module = "test"}, pattern = "@(.-)@", prefixdir = "header"})
    add_configfiles("*.man", {onlycopy = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config2/header")
