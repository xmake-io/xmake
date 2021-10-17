target("test")
    set_kind("binary")
    add_includedirs("src")
    add_rules("c++.unit_build", {batchsize = 2})
    add_files("src/*.c", "src/*.cpp")
    add_files("src/foo/*.c", {unit_group = "foo"})
    add_files("src/bar/*.c", {unit_group = "bar"})

