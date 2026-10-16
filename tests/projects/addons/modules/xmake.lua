add_repositories("example-modules-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-modules")

target("hello")
    set_kind("phony")
    on_run(function ()
        import("@addon.example-modules.greeting")
        print(greeting("xmake"))
    end)
