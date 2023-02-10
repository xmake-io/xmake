add_rules("mode.debug", "mode.release")

add_requires("llvm", {kind = "library", configs = {mlir = true}})

target("testllvm")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("llvm", {components = "mlir"})

