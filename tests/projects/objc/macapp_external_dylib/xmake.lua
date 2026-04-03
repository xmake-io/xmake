add_rules("mode.release", "mode.debug")

set_languages("c11", "objc")

target("demo")
    add_rules("xcode.application")
    add_linkdirs("ext")
    add_links("extfoo")
    add_files("src/main.m")
    add_files("src/Info.plist")
