add_rules("mode.debug", "mode.release")
add_requires("nuget::Humanizer.Core 2.14.1")

target("app")
    set_kind("binary")
    add_rules("csharp")
    add_files("src/Program.cs")
    add_packages("nuget::Humanizer.Core")
