add_rules("mode.debug", "mode.release")

target("mylib")
    set_kind("static")
    add_rules("csharp")
    add_files("src/lib/*.cs", "src/lib/lib.csproj")

target("app")
    set_kind("binary")
    add_rules("csharp")
    add_deps("mylib")
    add_files("src/app/*.cs", "src/app/app.csproj")
