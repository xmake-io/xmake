add_rules("mode.debug", "mode.release")
add_requires("llvm 14.0.0", {alias = "llvm-14"})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("llvm@llvm-14")
