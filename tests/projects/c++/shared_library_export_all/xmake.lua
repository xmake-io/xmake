add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("shared")
    add_files("src/foo.cpp")
    add_rules("utils.symbols.export_all", {with_classes = true})

target("demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")


