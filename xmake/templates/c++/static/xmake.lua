add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("static")
    add_files("src/foo.cpp")

target("${TARGET_NAME}")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")

${FAQ}
