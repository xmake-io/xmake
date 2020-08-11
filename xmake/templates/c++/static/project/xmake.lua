add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("static")
    add_files("src/interface.cpp")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("${TARGETNAME}")
    add_files("src/main.cpp")

${FAQ}
