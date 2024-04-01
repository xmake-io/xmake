add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("test")
    add_rules("module.binary")
    add_files("src/*.cpp")
    on_config(function (target)
--        import("shared.foo")
        import("binary.bar")
--        print("1 + 1 = %d", foo.add(1, 1))
        print("%s", bar("hello", "xmake!"))
    end)

