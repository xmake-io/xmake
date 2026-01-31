add_rules("mode.debug", "mode.release")

target("enabled")
    set_kind("binary")
    add_files("src/main.c")

target("disabled")
    set_kind("binary")
    add_files("src/main.c")
    set_policy("generator.compile_commands", false)
