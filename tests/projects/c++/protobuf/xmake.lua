add_rules("mode.debug", "mode.release")

add_requires("protobuf-cpp")
if is_cross() then
    add_requires("protoc")
end

target("test")
    set_kind("binary")
    set_languages("c++17")
    add_rules("protobuf.cpp")
    add_files("src/*.cpp")
    add_files("src/**.proto", {proto_rootdir = "src"})

    add_packages("protobuf-cpp")
    if is_cross() then
        add_packages("protoc")
    end

