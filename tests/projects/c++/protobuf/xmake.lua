add_rules("mode.debug", "mode.release")
add_requires("protobuf-cpp")

target("test")
    set_kind("binary")
    set_languages("c++11")
    add_packages("protobuf-cpp")
    add_rules("protobuf.cpp")
    add_files("src/*.cpp")
    add_files("src/**.proto", {proto_rootdir = "src"})

