add_rules("mode.debug", "mode.release")

target("libalpha")
    set_kind("static")
    add_rules("csharp")
    add_files("src/libalpha/*.cs", "src/libalpha/libalpha.csproj")

target("libbeta")
    set_kind("static")
    add_rules("csharp")
    add_deps("libalpha")
    add_files("src/libbeta/*.cs", "src/libbeta/libbeta.csproj")

target("sample")
    set_kind("binary")
    add_rules("csharp")
    add_deps("libbeta")
    add_files("src/sample/*.cs", "src/sample/sample.csproj")