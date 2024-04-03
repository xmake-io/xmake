add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    on_config(function (target)
        import("shared.foo")
        import("shared.zoo", {always_build = true})
        import("binary.bar", {always_build = true})
        print("foo: 1 + 1 = %d", foo.add(1, 1))
        print("foo: 1 - 1 = %d", foo.sub(1, 1))
        print("zoo: 1 + 1 = %d", zoo.add(1, 1))
        print("zoo: 1 - 1 = %d", zoo.sub(1, 1))
        print("bar: 1 + 1 = %s", bar.add(1, 1))
        print("bar: 1 - 1 = %s", bar.sub(1, 1))
    end)

