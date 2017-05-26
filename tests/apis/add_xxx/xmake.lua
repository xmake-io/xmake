add_defines("TEST1")

target("test")

    add_defines("TEST2")
    on_build(function (target)
        local defines = table.concat(target:get("defines"), " ")
        assert(defines:find("TEST1", 1, true))
        assert(defines:find("TEST2", 1, true))
    end)

