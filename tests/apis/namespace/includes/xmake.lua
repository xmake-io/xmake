add_rules("mode.debug", "mode.release")

add_defines("ROOT")

namespace("ns1", function ()
    add_defines("NS1_ROOT")
    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        add_defines("FOO")

    includes("src")
end)

target("test")
    set_kind("binary")
    add_deps("ns1::foo", "ns1::ns2::bar")
    add_files("src/main.cpp")
    add_defines("TEST")

