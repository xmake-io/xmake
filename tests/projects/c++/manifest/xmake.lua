add_rules("mode.debug", "mode.release")

target("test1")
    set_kind("binary")
    add_files("src/*.cpp")
    add_files("src/*.manifest")

target("test2")
    set_kind("binary")
    add_files("src/*.cpp")
    set_policy("windows.manifest.uac", "admin")

