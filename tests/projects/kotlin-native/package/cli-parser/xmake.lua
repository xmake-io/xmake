add_rules("mode.debug", "mode.release")

add_requires("kotlin-native")
add_requires("kotlin-native::org.jetbrains.kotlinx:kotlinx-cli 0.3.6", {alias = "kotlinx-cli"})

target("test")
    set_kind("binary")
    add_files("src/*.kt")
    add_packages("kotlinx-cli")
    set_toolchains("@kotlin-native")
