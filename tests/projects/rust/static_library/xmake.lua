add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("static")
    add_files("src/foo.rs")

target("test")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.rs")


