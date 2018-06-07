
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.d") 

