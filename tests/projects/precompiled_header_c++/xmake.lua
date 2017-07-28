-- define target
target("main")

    -- set kind
    set_kind("binary")

    -- set language: c++11
    set_languages("cxx11")

    -- set precompiled header
    set_precompiled_header("src/header.hpp")

    -- add files
    add_files("src/*.cpp")

