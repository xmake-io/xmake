add_rules("mode.debug", "mode.release")

rule("rule0")
    on_load(function (target)
        target:add("defines", "RULE0")
    end)

namespace("ns1", function ()
    rule("rule1")
        on_load(function (target)
            target:add("defines", "NS1_RULE1")
        end)

    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        add_rules("rule1")

    namespace("ns2", function()
        rule("rule2")
            on_load(function (target)
                target:add("defines", "NS2_RULE2")
            end)

        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
            add_rules("rule2")
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
        add_rules("rule0", "rule1", "ns2::rule2")
end)

