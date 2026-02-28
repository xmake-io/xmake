add_rules("mode.debug", "mode.release")

target("webapp")
    set_kind("binary")
    add_rules("csharp")
    add_values("csharp.sdk", "Microsoft.NET.Sdk.Web")
    add_files("src/Program.cs")
