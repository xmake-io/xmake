add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("static")
    add_files("src/test.zig")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("${TARGETNAME}")
    add_files("src/main.zig")

${FAQ}
