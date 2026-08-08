target("foo")
    set_kind("static")
    add_files("src/foo.cs")

target("${TARGET_NAME}_demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cs")

${FAQ}
