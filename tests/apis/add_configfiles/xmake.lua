
option("foo")
    set_default("foo")
    set_description("The Foo Info")
option_end()

if has_config("foo") then
    set_configvar("FOO_ENABLE", 1)
    set_configvar("FOO_ENABLE2", false)
    set_configvar("FOO_STRING", get_config("foo"))
end

option("foo2")
    set_default(true)
    set_description("Enable Foo2")
    set_configvar("FOO2_ENABLE", true)
    set_configvar("FOO2_STRING", "foo")
option_end()

target("test")
    set_kind("binary")
    add_files("main.c")

    set_configvar("module", "test")
    set_configdir("$(buildir)/config")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config.h.in", {variables = {hello = "xmake"}, prefixdir = "header"})
    add_configfiles("*.man", {copyonly = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config/header")


target("test2")
    set_kind("binary")
    add_files("main2.c")

    set_configvar("module", "test2")
    set_configdir("$(buildir)/config2")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config2.h.in", {variables = {hello = "xmake2"}, pattern = "@(.-)@", prefixdir = "header"})
    add_configfiles("*.man", {onlycopy = true, prefixdir = "man"})
    add_includedirs("$(buildir)/config2/header")

    add_options("foo2")
