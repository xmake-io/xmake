add_rules("mode.debug", "mode.release")

-- MyLib.dll under lib/ is a prebuilt fixture (not an xmake target, not a NuGet package) -
-- exactly the case csharp.references exists for: referencing an external assembly by path.
target("app")
    set_kind("binary")
    add_files("src/app/*.cs")
    add_values("csharp.references", "lib/MyLib.dll")
