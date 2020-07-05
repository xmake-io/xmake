add_rules("mode.debug", "mode.release")

target("testlib")
    set_kind("shared")
    add_files("src/test.f90")

target("test")
    set_kind("binary")
    add_deps("testlib")
    add_files("src/main.f90")

