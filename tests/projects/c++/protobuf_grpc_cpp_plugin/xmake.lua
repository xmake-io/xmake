add_rules("mode.debug", "mode.release")
add_requires("protobuf-cpp")
add_requires("grpc", {system = false})

target("test")
    set_kind("binary")
    set_languages("c++17")
    add_packages("protobuf-cpp")
    add_packages("grpc")
    add_rules("protobuf.cpp")
    add_files("src/*.cpp")
    add_files("src/test.proto", {proto_rootdir = "src", proto_grpc_cpp_plugin = true})
    add_files("src/subdir/test2.proto", {proto_rootdir = "src"})

