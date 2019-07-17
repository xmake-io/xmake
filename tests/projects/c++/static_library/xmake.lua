-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("static_library_c++")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/interface.cpp") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("static_library_c++")

    -- add files
    add_files("src/test.cpp") 


