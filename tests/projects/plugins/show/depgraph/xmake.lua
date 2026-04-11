add_rules("mode.debug", "mode.release")

target("core")
    set_kind("static")
    add_files("src/core.c")

target("ui")
    set_kind("static")
    add_deps("core")
    add_files("src/ui.c")

target("app")
    set_kind("binary")
    add_deps("core", "ui")
    add_files("src/main.c")
