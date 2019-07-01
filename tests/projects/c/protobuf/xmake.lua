
-- add rules: debug and release
add_rules("mode.debug", "mode.release")

-- add protobuf
add_requires("protobuf-c")

-- add target
target("console_c")

    -- set kind
    set_kind("binary")

    -- add packages
    add_packages("protobuf-c")

    -- add files
    add_files("src/*.c")
    add_files("src/*.proto", {rules = "protobuf.c"})

