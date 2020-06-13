add_rules("mode.debug", "mode.release")
add_requires("protobuf-c")

target("test")
    set_kind("binary")
    add_packages("protobuf-c")
    add_files("src/*.c")
    add_files("src/**.proto", {rules = "protobuf.c", proto_rootdir = "src"})

