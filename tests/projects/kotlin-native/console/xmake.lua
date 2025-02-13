add_rules("mode.debug", "mode.release")
add_requires("kotlin-native")
target("test")
    set_kind("binary")
    add_files("src/*.kt")
    set_toolchains("@kotlin-native")

