add_rules("mode.debug", "mode.release")

add_requires("glslang", {configs = {binaryonly = true}})

target("test")
    set_kind("binary")
    add_rules("utils.hlsl2spv", {bin2obj = true})
    add_files("src/*.c")
    add_files("src/*.hlsl")
    add_packages("directxshadercompiler")

