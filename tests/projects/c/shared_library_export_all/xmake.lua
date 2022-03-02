add_rules("mode.release", "mode.debug")

target("foo")
    set_kind("shared")
    add_files("src/foo.c", "src/bar.cpp")
    add_rules("utils.symbols.export_all", {export_classes = true})

target("test")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.c")


