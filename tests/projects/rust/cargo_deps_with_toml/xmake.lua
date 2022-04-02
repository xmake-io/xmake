add_rules("mode.release", "mode.debug")
add_requires("cargo::test", {configs = {tomlfile = path.join(os.projectdir(), "Cargo.toml")}})

target("test")
    set_kind("binary")
    add_files("src/main.rs")
    add_packages("cargo::test")
