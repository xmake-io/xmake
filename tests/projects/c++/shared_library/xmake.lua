add_rules("mode.debug", "mode.release")

target("test")
    set_kind("shared")
    add_files("src/interface.cpp")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.cpp")


