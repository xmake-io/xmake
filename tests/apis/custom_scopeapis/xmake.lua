add_rules("mode.debug", "mode.release")

interp_add_scopeapis("myscope.set_name", "myscope.add_list", {kind = "values"})

myscope("hello")
    set_name("foo")
    add_list("value1", "value2")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")


