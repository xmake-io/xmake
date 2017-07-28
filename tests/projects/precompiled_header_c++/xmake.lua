-- define target
target("main")

    -- set kind
    set_kind("binary")

    set_precompiled_header("src/header.hpp")

    -- add files
    add_files("src/*.cpp")

