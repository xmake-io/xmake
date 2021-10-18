target("test")
    set_kind("binary")
    add_includedirs("src")
    add_rules("c.unity_build", {batchsize = 2})
    add_files("src/*.c", "src/*.cpp")
    add_files("src/foo/*.c", {unity_group = "foo"})
    add_files("src/bar/*.c", {unity_group = "bar"})

