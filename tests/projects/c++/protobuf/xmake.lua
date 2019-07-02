
-- add rules: debug and release
add_rules("mode.debug", "mode.release")

-- add protobuf
add_requires("protobuf-cpp")

-- add target
target("console_c++")

    -- set kind
    set_kind("binary")

    -- set languages
    set_languages("c++11")

    -- add packages
    add_packages("protobuf-cpp")

    -- add files
    add_files("src/*.cpp")
    add_files("src/*.proto", {rules = "protobuf.cpp"})

