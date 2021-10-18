target("test")
    set_kind("binary")
    add_includedirs("src")
    add_rules("c++.unity_build", {batchsize = 2, uniqueid = "MY_UNITY_ID"})
    add_files("src/*.c", "src/*.cpp")
    add_files("src/foo/*.cpp", {unity_group = "foo"})
    add_files("src/bar/*.cpp", {unity_group = "bar"})


