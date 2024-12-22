add_rules("mode.debug", "mode.release")

namespace("ns1", function ()
    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")

    namespace("ns2")
        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
    namespace_end()
end)

target("test")
    set_kind("binary")
    add_deps("ns1::foo", "ns1::ns2::bar")
    add_files("src/main.cpp")

