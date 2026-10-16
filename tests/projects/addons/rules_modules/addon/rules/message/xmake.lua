rule("message")
    on_load(function (target)
        -- @self keeps addon-internal imports independent of the addon's name.
        import("@self.greeting")
        target:add("defines", greeting.define())
    end)
