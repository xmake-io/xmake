add_rules("mode.debug", "mode.release")

target("console_objc++")
    set_kind("binary")
    add_files("src/*.mm")

