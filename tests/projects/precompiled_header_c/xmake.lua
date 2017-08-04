-- define target
target("main")

    -- set kind
    set_kind("binary")

    -- set precompiled header
    set_pcheader("src/header.h")

    -- add files
    add_files("src/*.c", "src/*.cpp")

