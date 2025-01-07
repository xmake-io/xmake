
toolchain("toolchain0")
    on_load(function (toolchain)
        toolchain:add("defines", "TOOLCHAIN0")
    end)

namespace("ns1", function ()
    toolchain("toolchain1")
        on_load(function (toolchain)
            toolchain:add("defines", "NS1_TOOLCHAIN1")
        end)

    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        set_toolchains("toolchain1")

    namespace("ns2", function()
        toolchain("toolchain2")
            on_load(function (toolchain)
                toolchain:add("defines", "NS2_TOOLCHAIN2")
            end)

        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
            set_toolchains("toolchain2")
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
        set_toolchains("toolchain0", "toolchain1", "ns2::toolchain2")
end)

