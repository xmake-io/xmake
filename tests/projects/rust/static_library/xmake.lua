add_rules("mode.debug", "mode.release")

target("interfaces")
    set_kind("static")
    add_files("src/interfaces.rs")

target("test")
    set_kind("binary")
    add_deps("interfaces")
    add_files("src/main.rs")


