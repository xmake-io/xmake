add_rules("mode.debug", "mode.release")

option("opt0", {default = true, defines = "OPT0", description = "option0"})

namespace("ns1", function ()
    option("opt1", {default = true, defines = "NS1_OPT1", description = "option1"})

    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        add_options("opt1")
        if has_config("opt1") then
            add_defines("HAS_NS1_OPT1")
        end

    namespace("ns2", function()
        option("opt2", {default = true, defines = "NS2_OPT2", description = "option2"})
        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
            add_options("opt2")
            if has_config("opt2") then
                add_defines("HAS_NS2_OPT2")
            end
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
        add_options("opt0", "opt1", "ns2::opt2")
        on_load(function (target)
            if has_config("opt0") then
                target:add("defines", "HAS_OPT0")
            end
            if has_config("opt1") then
                target:add("defines", "HAS_NS1_OPT1")
            end
            if has_config("ns2::opt2") then
                target:add("defines", "HAS_NS2_OPT2")
            end
        end)
end)

