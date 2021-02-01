add_rules("mode.debug", "mode.release")
add_requires("llvm 11.0.0")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("llvm", {packages = "llvm-11"})
