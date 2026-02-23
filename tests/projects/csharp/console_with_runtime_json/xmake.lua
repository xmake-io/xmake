add_rules("mode.debug", "mode.release")

target("app")
    set_kind("binary")
    add_rules("csharp")
    add_files("src/Program.cs", "src/app.csproj")
