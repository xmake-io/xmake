add_rules("mode.release", "mode.debug")

target("test")
    set_kind("binary")
    add_files("src/*.vala")
