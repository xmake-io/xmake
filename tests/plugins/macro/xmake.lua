add_rules("mode.debug", "mode.release")

target("macro")
    set_kind("binary")
    add_files("src/*.cpp")

