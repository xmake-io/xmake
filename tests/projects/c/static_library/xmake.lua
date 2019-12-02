add_rules("mode.release", "mode.debug")

target("static_library_c")
    set_kind("static")
    add_files("src/interface.c")

target("test")
    set_kind("binary")
    add_deps("static_library_c")
    add_files("src/test.c")


