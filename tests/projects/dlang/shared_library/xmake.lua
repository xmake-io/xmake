-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("interfaces")

    -- set kind
    set_kind("shared")

    -- add files
    add_files("src/interfaces.d") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("interfaces")

    -- add files
    add_files("src/main.d") 

    -- add links
    add_links("interfaces")

    -- add link directory
    add_linkdirs("$(buildir)")
    add_rpathdirs("$(buildir)")

    -- add include directory
    add_includedirs("$(projectdir)/src")

