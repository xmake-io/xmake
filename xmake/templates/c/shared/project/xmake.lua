add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("shared")
    add_files("src/foo.c")

target("${TARGETNAME}")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.c")

${FAQ}
