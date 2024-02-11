add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("foo")
    set_kind("moduleonly")
    add_files("src/foo.mpp")

target("bar")
    set_kind("moduleonly")
    add_files("src/bar.mpp")

target("link_order_1")
    set_kind("binary")
    add_deps("foo", "bar")
    add_files("src/main.cpp")

target("link_order_2")
    set_kind("binary")
    add_deps("bar", "foo")
    add_files("src/main.cpp")
