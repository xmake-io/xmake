add_rules("mode.release", "mode.debug")

target("shared_library_c")
    set_kind("shared")
    add_files("src/interface.c")

target("test")
    set_kind("binary")
    add_deps("shared_library_c")
    add_files("src/test.c")


