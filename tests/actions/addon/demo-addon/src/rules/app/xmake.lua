rule("app")
    add_deps("@self/base")
    on_load(function (target)
        import("@self.greeting")
        import("core.package.addon")
        -- the addon code should never hardcode its own name, it can always ask for it
        local addonname = addon.owner()
        print("demo-addon: rule app is loaded by the addon(%s), %s", addonname, greeting(target:name()))
    end)
