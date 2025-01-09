add_rules("mode.debug", "mode.release")

namespace("ns1", function ()
    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")

    namespace("ns2", function()
        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
end)

