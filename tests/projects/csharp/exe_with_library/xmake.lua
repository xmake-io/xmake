add_rules("mode.debug", "mode.release")

target("mylib")
    set_kind("shared")
    add_rules("csharp")
    add_files("src/lib/*.cs")

target("app")
    set_kind("binary")
    add_rules("csharp")
    add_deps("mylib")
    add_files("src/app/*.cs")
