add_rules("mode.debug", "mode.release")

add_requires("directxshadercompiler", {configs = {binaryonly = true}})

target("test")
    set_kind("binary")
    add_rules("utils.hlsl2spv", {bin2c = true})
    add_files("src/*.c")
    add_files("src/*.vs.hlsl", "src/*.ps.hlsl")
    add_packages("directxshadercompiler")

