add_rules("mode.debug", "mode.release")

add_requires("kotlin-native")
add_requires("kotlin-native::org.jetbrains.kotlinx:kotlinx-serialization-json 1.8.0", {alias = "json"})
add_requires("kotlin-native::org.jetbrains.kotlinx:kotlinx-serialization-core 1.8.0", {alias = "core"})

target("test")
    set_kind("binary")
    add_files("src/*.kt")
    add_packages("json", "core")
    set_toolchains("@kotlin-native")
