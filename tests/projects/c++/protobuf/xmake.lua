add_rules("mode.debug", "mode.release")

add_requires("protoc", "protobuf-cpp")
-- add_requireconfs("protoc.protobuf-cpp", {version = "1.0.0"})

target("test")
    set_kind("binary")
    set_languages("c++17")
    add_rules("protobuf.cpp")
    add_files("src/*.cpp")
    add_files("src/**.proto", {proto_rootdir = "src"})

    add_packages("protoc", "protobuf-cpp")

