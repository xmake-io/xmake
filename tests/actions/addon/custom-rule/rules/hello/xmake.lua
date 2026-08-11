rule("hello")
    on_load(function (target)
        -- the addon code refers to its own resources with `@self`
        import("@self.greeting")
        print("custom-rule: %s", greeting(target:name()))
    end)
