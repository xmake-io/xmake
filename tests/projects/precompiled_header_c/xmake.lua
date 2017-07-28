-- define target
target("main")

    -- set kind
    set_kind("binary")

    -- set precompiled header
    set_precompiled_header("src/header.h", "src/header.c")

    -- add files
    add_files("src/*.c|header.c")

