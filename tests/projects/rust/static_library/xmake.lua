-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("interfaces")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/interfaces.rs") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("interfaces")

    -- add files
    add_files("src/main.rs") 

    -- add link directory
    add_linkdirs("$(buildir)/$(mode)/$(arch)")


