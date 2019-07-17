-- add rules
add_rules("mode.debug", "mode.release")

-- define target
target("main")

    -- set kind
    set_kind("binary")

    -- set language: c++11
    set_languages("cxx11")

    -- set precompiled header
    set_pcxxheader("src/header.h")

    -- add files
    add_files("src/*.cpp", "src/*.c", "*.cpp")

