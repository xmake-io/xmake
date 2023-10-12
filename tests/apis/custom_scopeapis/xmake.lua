add_rules("mode.debug", "mode.release")

interp_add_scopeapis("myscope.set_name", "myscope.add_list", {kind = "values"})
interp_add_scopeapis("myscope.on_script", {kind = "script"})

myscope("hello")
    set_name("foo")
    add_list("value1", "value2")
    on_script(function ()
        print("hello")
    end)

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    on_config(function (target)
        import("core.project.project")
        local myscope = project.scope("myscope")
        for name, scope in pairs(myscope) do
            print("myscope(%s)", name)
            print("    name: %s", scope:get("name"))
            print("    list: %s", table.concat(scope:get("list"), ", "))
            print("    script:")
            local script = scope:get("script")
            if script then
                script()
            end
        end
    end)


