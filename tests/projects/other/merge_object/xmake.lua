-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("merge_object")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/interface.c") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("merge_object")

    -- add files
    add_files("src/test.c") 
    add_files("build/.objs/merge_object/src/interface.c.o")

