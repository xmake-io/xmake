-- rustup target add aarch64-unknown-none
-- xmake f -a aarch64-unknown-none

set_arch("aarch64-unknown-none")
add_rules("mode.release", "mode.debug")
add_requires("cargo::test", {configs = {
    std = false,
    main = false,
    cargo_toml = path.join(os.projectdir(), "Cargo.toml")}})

target("test")
    set_kind("binary")
    add_files("src/main.rs")
    add_packages("cargo::test")
