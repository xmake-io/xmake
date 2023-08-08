add_rules("mode.release", "mode.debug")
add_requires("cargo::test", {configs = {
    std = false,
    main = false,
    build_target = "aarch64-unknown-none",
    cargo_toml = path.join(os.projectdir(), "Cargo.toml")}})

target("test")
    set_kind("binary")
    add_files("src/main.rs")
    add_packages("cargo::test")
