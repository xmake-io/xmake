add_rules("mode.debug", "mode.release")

target("bar")
    set_kind("binary")
    add_files("src/*.cpp")


