rule("dep")

    -- depend on a rule of the other addon
    add_deps("@addon/demo-addon/base")

    on_load(function (target)
        -- import a module of the other addon
        import("@addon.demo-addon.greeting")
        print("demo-addon-dep: " .. greeting("dep"))
    end)
