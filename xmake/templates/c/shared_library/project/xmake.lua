
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("[targetname]")

    -- set kind
    set_kind("shared")

    -- add files
    add_files("src/interface.c") 

-- add target
target("[targetname]_demo")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("[targetname]")

    -- add files
    add_files("src/test.c") 


