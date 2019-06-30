
-- add rules: debug and release
add_rules("mode.debug", "mode.release")

-- add protobuf
add_requires("protobuf-cpp", "protoc")

-- add target
target("console_c++")

    -- set kind
    set_kind("binary")

    -- add rules and packages
    add_rules("protobuf.cpp")
    add_packages("protobuf-cpp", "protoc")

    -- add files
    add_files("src/*.cpp", "src/*.proto") 

