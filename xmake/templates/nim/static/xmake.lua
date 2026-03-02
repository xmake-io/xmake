add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}")
    set_kind("static")
    add_files("src/foo.nim")

target("${TARGET_NAME}_demo")
    set_kind("binary")
    add_deps("${TARGET_NAME}")
    add_files("src/main.nim")

${FAQ}


