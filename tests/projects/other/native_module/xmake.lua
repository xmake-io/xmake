add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    on_config(function (target)
--        import("shared.foo")
        import("binary.bar")
--        print("shared: 1 + 1 = %d", foo.add(1, 1))
--        print("shared: 1 - 1 = %d", foo.sub(1, 1))
        print("binary: 1 + 1 = %s", bar.add("1", "1"))
        print("binary: 1 - 1 = %s", bar.sub("1", "1"))
    end)

