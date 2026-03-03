add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}")
    set_kind("binary")
    add_files("src/*.zig")

${FAQ}
