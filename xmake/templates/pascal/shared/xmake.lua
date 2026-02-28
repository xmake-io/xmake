add_rules("mode.debug", "mode.release")
target("foo")
    set_kind("shared")
    add_files("src/foo.pas")

target("${TARGET_NAME}")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.pas")


${FAQ}
