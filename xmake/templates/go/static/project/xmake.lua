add_rules("mode.debug", "mode.release")

target("module")
    set_kind("static")
    add_files("src/module/*.go")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("module")
    add_files("src/*.go")

${FAQ}
