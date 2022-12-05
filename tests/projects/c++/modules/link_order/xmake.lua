add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("foo")
    add_rules("c++")
    set_kind("static")
    add_files("src/foo.mpp")

target("bar")
    add_rules("c++")
    set_kind("static")
    add_files("src/bar.mpp")

target("link_order_1")
    set_kind("binary")
    add_deps("foo", "bar")
    add_defines("VALUE=value1")
    add_files("src/main.cpp")

target("link_order_2")
    set_kind("binary")
    add_deps("bar", "foo")
    add_defines("VALUE=value2")
    add_files("src/main.cpp")