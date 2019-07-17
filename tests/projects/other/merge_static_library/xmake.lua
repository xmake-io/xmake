-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("add")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/add.c") 

-- add target
target("sub")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/sub.c") 

-- add target
target("mul")

    -- set kind
    set_kind("static")

    -- add deps
    add_deps("add", "sub")

    -- add files
    add_files("src/mul.c") 
    add_files("build/libadd.a")
    add_files("build/libsub.a")

    -- add link directory
    add_linkdirs("$(buildir)")

