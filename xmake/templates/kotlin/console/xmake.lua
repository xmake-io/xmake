add_rules("mode.debug", "mode.release")

add_requires("kotlin-native")

target("${TARGET_NAME}")
    set_kind("binary")
    add_files("src/main.kt")
    set_toolchains("@kotlin-native")

${FAQ}
