add_rules("mode.release", "mode.debug")
add_requires("cargo::base64")

target("test")
    set_kind("binary")
    add_files("src/main.rs")
    add_packages("cargo::base64")
