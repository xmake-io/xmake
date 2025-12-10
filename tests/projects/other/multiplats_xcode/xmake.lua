add_rules("mode.debug", "mode.release")
target("test_host")
    set_kind("binary")
    add_files("src/*.c")

target("test_iphoneos")
    set_kind("binary")
    add_files("src/*.c")
    set_plat("iphoneos")
