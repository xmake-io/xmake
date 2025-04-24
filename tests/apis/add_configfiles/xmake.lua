
option("foo")
    set_default("foo")
    set_description("The Foo Info")
option_end()

if has_config("foo") then
    set_configvar("FOO_ENABLE", 1)
    set_configvar("FOO_ENABLE2", false)
    set_configvar("FOO_STRING", get_config("foo"))
    set_configvar("FOO_DEFINE", get_config("foo"), {quote = false})
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
    set_configdir("$(builddir)/config")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config.h.in", {variables = {hello = "xmake"}, prefixdir = "header",
        preprocessor = function (preprocessor_name, name, value, opt)
            if preprocessor_name == "define_custom" then
                return string.format("#define CUSTOM_%s %s", name, value)
            end
        end})
    add_configfiles("*.man", {onlycopy = true, prefixdir = "man"})
    add_includedirs("$(builddir)/config/header")


target("test2")
    set_kind("binary")
    add_files("main2.c")

    set_configvar("module", "test2")
    set_configdir("$(builddir)/config2")
    add_configfiles("test.c.in", {filename = "mytest.c"})
    add_configfiles("config2.h.in", {variables = {hello = "xmake2"}, pattern = "@([^\n]-)@", prefixdir = "header"})
    add_configfiles("*.man", {onlycopy = true, prefixdir = "man"})
    add_includedirs("$(builddir)/config2/header")

    add_options("foo2")
