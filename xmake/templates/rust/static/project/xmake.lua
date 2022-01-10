target("foo")
    set_kind("static")
    add_files("src/foo.rs")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.rs")

${FAQ}
