add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("shared")
    add_files("src/foo.nim")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("${TARGETNAME}")
    add_files("src/main.nim")

${FAQ}


