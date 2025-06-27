add_rules("mode.debug", "mode.release")

target("bar")
    set_kind("object")
    add_files("src/foo.cpp")

target("foo")
    set_kind("static")
    add_deps("bar")

target("object_only")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")

