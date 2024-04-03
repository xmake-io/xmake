add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

target("${TARGETNAME}")
    set_kind("binary")
    add_files("src/*.c")
    on_config(function (target)
        import("binary.bar")
        print("binary: 1 + 1 = %s", bar.add(1, 1))
        print("binary: 1 - 1 = %s", bar.sub(1, 1))
    end)
    
${FAQ}

