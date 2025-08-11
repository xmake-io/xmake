add_rules("mode.debug", "mode.release")

local language = "17"

add_requires("protoc", "protobuf-cpp")
-- add_requireconfs("protoc.protobuf-cpp", {override = true, version = "1.0.0"})
add_requireconfs("**.abseil", {override = true, configs = {cxx_standard = language}})

target("test")
    set_kind("binary")
    set_languages("c++" .. language)
    add_rules("protobuf.cpp")
    add_files("src/*.cpp")
    add_files("src/**.proto", {proto_rootdir = "src"})

    add_packages("protoc", "protobuf-cpp")

