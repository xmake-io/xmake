add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("${TARGETNAME}")
    set_kind("binary")
    add_files("src/*.c")
    on_config(function (target)
        import("shared.foo")
        print("shared: 1 + 1 = %s", foo.add(1, 1))
        print("shared: 1 - 1 = %s", foo.sub(1, 1))
    end)
    
${FAQ}

