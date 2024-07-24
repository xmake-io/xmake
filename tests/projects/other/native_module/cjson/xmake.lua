add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    on_config(function (target)
        import("lua.cjson", {always_build = true})
        print(cjson.decode('{"foo": 1, "bar": [1, 2, 3]}'))
    end)

